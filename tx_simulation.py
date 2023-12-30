import json
import os
import subprocess
import tempfile

import cbor2
import requests


def to_bytes(s: str) -> bytes:
    """ Convert the string to bytes and prepend with 'h' to indicate hexadecimal format.
    The bytes representation will be returned else a ValueError is raised.

    Args:
        s (str): The hexadecimal string used in byte conversion

    Returns:
        bytes: A bytestring in proper cbor format.
    """
    try:
        return bytes.fromhex(s)
    except ValueError:
        raise ValueError("non-hexadecimal number found in fromhex() arg at position 1")


def tx_draft_to_resolved_cbor(draft: str) -> list[any]:
    """ Decodes a hexadecimal string representing CBOR data into a Python object.

    Args:
        draft (str): A hexadecimal string representing CBOR data.

    Returns:
        list: A Python object obtained by decoding the CBOR data.

    Raises:
        ValueError: If the input string is not a valid hexadecimal or if the
                    decoded bytes are not valid CBOR data.
    """
    try:
        decoded_data = cbor2.loads(bytes.fromhex(draft))
    except ValueError:
        raise ValueError("non-hexadecimal number found in fromhex() arg at position 1")

    return decoded_data


def query_tx_with_koios(hashes: list[str], network: bool) -> list[dict]:
    """Uses Koios to query the transaction information from a list of
    transaction hashes. The return order may not match the input order.

    Args:
        hashes (list): The list of tx hashes.
        network (bool): The network flag, mainnet (True) or preprod (False).

    Returns:
        list: A list of transaction information.
    """
    # mainnet and preprod only
    subdomain = "api" if network is True else "preprod"

    json_data = {
        '_tx_hashes': hashes
    }

    headers = {
        'accept': 'application/json',
        'content-type': 'application/json',
    }

    url = 'https://' + subdomain + '.koios.rest/api/v0/tx_info'
    # return the tx information for a list of transactions, (the inputs)
    return requests.post(url=url, headers=headers, json=json_data).json()


def resolve_inputs_and_outputs(tx_cbor: str, network: bool) -> tuple[list[tuple[str, int]], list[dict]]:
    """Resolves the inputs and the inputs outputs for some given tx cbor. The returned values are not in
    any specific ordering.

    Args:
        tx_cbor (str): The transaction cbor
        network (bool): The network flag

    Raises:
        KeyError: The inputs, collateral, and reference inputs must exist inside the tx.

    Returns:
        tuple[list[tuple[str, int]], list[dict]]: A tuple of the utxo inputs and the resolved input outputs.
    """
    # resolve the data from the cbor
    data = tx_draft_to_resolved_cbor(tx_cbor)

    # we just need the body here
    try:
        txBody = data[0]

        # all the types of inputs; tx inputs, collateral, and reference
        inputs = txBody[0] + txBody[13] + txBody[18]
        # convert into list of tuples
        inputs = [(utxo[0].hex(), int(utxo[1])) for utxo in inputs]
    except KeyError:
        raise KeyError("required tx body elements are missing")

    # we now need to loop all the input hashes to resolve their outputs
    # utxo inputs have the form [tx_hash, index]
    tx_hashes = [utxo[0] for utxo in inputs]
    outputs = query_tx_with_koios(tx_hashes, network)
    return inputs, outputs


def resolve_value_from_input_output(lovelace: int, assets: list[dict]) -> int | list:
    """
    Resolves the value from the input or output of a transaction.

    Args:
        lovelace (int): The amount in Lovelace.
        assets (List[Dict[str, Any]]): A list of additional assets involved in the transaction.
            Each asset is represented as a dictionary with keys for 'policy_id', 'asset_name', and 'quantity'.

    Returns:
        Union[int, List[Any]]: The resolved value. Returns an integer if only Lovelace is involved.
            Returns a list containing the Lovelace amount and a dictionary of assets if additional assets are involved.
    """
    # its just an int when its lovelace only
    if len(assets) == 0:
        value = int(lovelace)
    else:
        # build out the assets then create the asset list
        tokens = {}
        for asset in assets:
            pid = to_bytes(asset['policy_id'])
            tkn = to_bytes(asset['asset_name'])
            amt = int(asset['quantity'])
            # initialize the dict
            if pid not in tokens:
                tokens[pid] = {}
            # its already a dict
            tokens[pid][tkn] = amt

        # the form for assets is a list
        value = [int(lovelace), tokens]
    return value


def from_cbor(tx_cbor: str, network: bool, debug: bool = False, aiken_path: str = 'aiken') -> list[dict]:
    """Simulate a tx from tx cbor for some network.

    Args:
        tx_cbor (str): The transaction cbor.
        network (bool): The network flag, mainnet (True) or preprod (False).
        debug (bool, optional): Debug prints to console. Defaults to False.
        aiken_path (str, optional): The path to aiken. Defaults to 'aiken'.

    Returns:
        dict: Either an empty dictionary or a dictionary of the cpu and mem units.
    """
    # # resolve the input and output from the cbor
    inputs, resolved_inputs_outputs = resolve_inputs_and_outputs(tx_cbor, network)
    input_cbor = cbor2.dumps(inputs).hex()

    # build out the list of outputs
    outputs = []

    # the order of the resolved outputs matter so we match to the inputs
    for utxo in inputs:
        input_tx_hash = utxo[0]

        # now find the result for that hash
        for tx_input_output in resolved_inputs_outputs:
            that_tx_hash = tx_input_output['tx_hash']
            if input_tx_hash != that_tx_hash:
                # have to match the hashes so the we can resolve a specific tx input
                continue

            resolved = {}
            for txo in tx_input_output['outputs']:
                idx = txo['tx_index']

                # we found it
                if (to_bytes(input_tx_hash), idx) in inputs:
                    # lets build out the resolved output

                    # assume that anything with a datum is a contract
                    if utxo['inline_datum'] is not None:
                        network_flag = "71" if network is True else "70"
                        pkh = network_flag + txo['payment_addr']['cred']
                        pkh = to_bytes(pkh)
                        resolved[0] = pkh

                        # put the inline datum in the correct format
                        cbor_datum = to_bytes(utxo['inline_datum']['bytes'])
                        resolved[2] = [1, cbor2.CBORTag(24, cbor_datum)]
                    else:
                        # simple payment
                        network_flag = "61" if network is True else "60"
                        pkh = network_flag + utxo['payment_addr']['cred']
                        pkh = to_bytes(pkh)
                        resolved[0] = pkh

                    if utxo['reference_script'] is not None:
                        # assume plutus v2 reference scripts
                        cbor_ref = to_bytes(utxo['reference_script']['bytes'])
                        cbor_ref = to_bytes(cbor2.dumps([2, cbor_ref]).hex())

                        # put the reference script in the correct format
                        resolved[3] = cbor2.CBORTag(24, cbor_ref)

                    # now we need the value element
                    lovelace = txo['value']
                    assets = txo['asset_list']

                    # lovelace only is int, else it has assets
                    value = resolve_value_from_input_output(lovelace, assets)
                    resolved[1] = value

                    # append it and go to the next one
                    outputs.append(resolved)
                    break

    # get the resolved output cbor
    output_cbor = cbor2.dumps(outputs).hex()

    # attempt to debug if required
    if debug is True:
        print(tx_cbor, '\n')
        print(input_cbor, '\n')
        print(output_cbor, '\n')

    # try to simulate the tx and return the results else return an empty dict
    try:
        # use some temp files that get deleted later
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_tx_file:
            temp_tx_file.write(tx_cbor)
            temp_tx_file_path = temp_tx_file.name
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_input_file:
            temp_input_file.write(input_cbor)
            temp_input_file_path = temp_input_file.name
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_output_file:
            temp_output_file.write(output_cbor)
            temp_output_file_path = temp_output_file.name

        # the default value assumes aiken to be on path
        # or it uses the aiken path
        output = subprocess.run(
            [aiken_path, 'tx', 'simulate', temp_tx_file_path,
                temp_input_file_path, temp_output_file_path],
            check=True,
            capture_output=True,
            text=True
        )

        # this should remove the temp files
        os.remove(temp_tx_file_path)
        os.remove(temp_input_file_path)
        os.remove(temp_output_file_path)

        return json.loads(output.stdout)
    except subprocess.CalledProcessError:
        # the simulation failed in some way
        return [{}]


def from_file(tx_draft_path: str, network: bool, debug: bool = False, aiken_path: str = 'aiken') -> dict:
    """Simulate a tx from a tx draft file for some network.

    Args:
        tx_draft_path (str): The path to the tx.draft file.
        network (bool): The network flag, mainnet (True) or preprod (False).
        debug (bool, optional): Debug prints to console. Defaults to False.
        aiken_path (str, optional): The path to aiken. Defaults to 'aiken'.

    Returns:
        dict: Either an empty dictionary or a dictionary of the cpu and mem units.
    """
    # get cborHex from tx draft
    with open(tx_draft_path, 'r') as file:
        data = json.load(file)
    cborHex = data['cborHex']
    return from_cbor(cborHex, network, debug, aiken_path)
