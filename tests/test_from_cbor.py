from tx_simulation import from_cbor

AIKEN_PATH = "./bin/aiken"
NETWORK = False


def get_first_line(file_path):
    """
    Reads the first line from a file.

    :param file_path: Path to the file
    :return: The first line of the file
    """
    try:
        with open(file_path, 'r') as file:
            return file.readline().rstrip()
    except IOError as e:
        print(f"Error reading file {file_path}: {e}")
        return None


def test_from_cbor_always_true():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/always_true.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, debug=False, plutus_version=2)
    expected_output = [{'mem': 7295, 'cpu': 1822407}]
    assert output == expected_output


def test_from_cbor_lock():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/lock.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{'mem': 111328, 'cpu': 42405034}]
    assert output == expected_output


def test_from_cbor_single_shot():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/single_shot.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{'mem': 60094, 'cpu': 19600721}]
    assert output == expected_output


# this should fail
def test_from_cbor_always_false():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/always_false.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{}]
    assert output == expected_output


# this should pass
def test_from_cbor_subtract_fee():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/subtract_fee.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{'mem': 169749, 'cpu': 58808412}]
    assert output == expected_output


# this should pass
def test_from_cbor_multi():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/multi.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{'mem': 7295, 'cpu': 1822407}, {'mem': 133896, 'cpu': 53176689}, {'mem': 75076, 'cpu': 28188500}]
    assert output == expected_output


def test_mint_and_fee():
    valid_hex_cbor = get_first_line("./example-contracts/scripts/cbor/mint_and_fee.cbor")
    output = from_cbor(valid_hex_cbor, NETWORK, plutus_version=2)
    # print('output', output)
    expected_output = [{'mem': 757860, 'cpu': 228847782}, {'mem': 340297, 'cpu': 97159189}]
    assert output == expected_output
