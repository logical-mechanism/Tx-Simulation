import pytest

from tx_simulation import query_tx_with_koios

GOOD_RESPONSE = [{'tx_hash': 'c9cc36ddd9447af626f2e99c99c5500256aefd5c9d9eb8e670c4f7a93c602a87', 'block_hash': '50f923b3b9d4a3f87c913aae07322e12e4edf5ee4b9c9450a44c6d02be30069e', 'block_height': 8360158, 'epoch_no': 392, 'epoch_slot': 29620, 'absolute_slot': 84010420, 'tx_timestamp': 1675576711, 'tx_block_index': 0, 'tx_size': 428, 'total_output': '49639501', 'fee': '174433', 'deposit': '0', 'invalid_before': None, 'invalid_after': '84021197', 'collateral_inputs': [], 'collateral_output': None, 'reference_inputs': [], 'inputs': [{'value': '10793548', 'tx_hash': '3e019ab09dca87167ab35ec8f8c89d660e00deff998ca226d07f9a2d9ab7273d', 'tx_index': 1, 'asset_list': [], 'datum_hash': None, 'stake_addr': 'stake1u8ncuurg3gkrxwk624wlrmcd30dyg9p7unxp8tpdc9h3ynqvvcx37', 'inline_datum': None, 'payment_addr': {'cred': '3a27a30b8b69d2faa226754c3ce2ec0335cca4a87a3da3d4dc75dfdc', 'bech32': 'addr1qyaz0gct3d5a974zye65c08zaspntn9y4parmg75m36alh883ecx3z3vxvad542a78hsmz76gs2raexvzwkzmst0zfxqv6c0qv'}, 'reference_script': None}], 'outputs': [{'value': '9639501', 'tx_hash': 'c9cc36ddd9447af626f2e99c99c5500256aefd5c9d9eb8e670c4f7a93c602a87', 'tx_index': 1, 'asset_list': [], 'datum_hash': None, 'stake_addr': 'stake1u8ncuurg3gkrxwk624wlrmcd30dyg9p7unxp8tpdc9h3ynqvvcx37', 'inline_datum': None, 'payment_addr': {'cred': '65e4642f35a14b7a97e5c97542b664b4a3912b9ffba95d2b872a61fc', 'bech32': 'addr1q9j7gep0xks5k75huhyh2s4kvj628yftnla6jhftsu4xrl883ecx3z3vxvad542a78hsmz76gs2raexvzwkzmst0zfxqyl3amv'}, 'reference_script': None}, {'value': '40000000', 'tx_hash': 'c9cc36ddd9447af626f2e99c99c5500256aefd5c9d9eb8e670c4f7a93c602a87', 'tx_index': 0, 'asset_list': [], 'datum_hash': None, 'stake_addr': 'stake1u9dhu8zugzvfv2k2zj8z0ymresy7dqfx3fvetkwjym5nkhg0a5l7c', 'inline_datum': None, 'payment_addr': {'cred': '99fc1a514a232b29a18db7635e6650b8cf65b65da83491532cb928dd', 'bech32': 'addr1qxvlcxj3fg3jk2dp3kmkxhnx2zuv7edktk5rfy2n9juj3h2m0cw9csycjc4v59ywy7fk8nqfu6qjdzjejhvayfhf8dwsttnjt6'}, 'reference_script': None}], 'withdrawals': [{'amount': '39020386', 'stake_addr': 'stake1u8ncuurg3gkrxwk624wlrmcd30dyg9p7unxp8tpdc9h3ynqvvcx37'}], 'assets_minted': [], 'metadata': None, 'certificates': [], 'native_scripts': [], 'plutus_contracts': []}]
BAD_RESPONSE = []
ERROR_RESPONSE = {'code': '22P02', 'details': 'Array value must start with "{" or dimension information.', 'hint': None, 'message': 'malformed array literal: "acab"'}


@pytest.mark.parametrize("network", [True, False])
def test_query_tx_with_koios_valid_hashes(requests_mock, network):
    fake_response = GOOD_RESPONSE  # Mock response data
    subdomain = "api" if network else "preprod"
    url = f'https://{subdomain}.koios.rest/api/v0/tx_info'
    requests_mock.post(url, json=fake_response)

    response = query_tx_with_koios(['valid_hash1', 'valid_hash2'], network)
    assert response == fake_response, "Response does not match expected mock data"


@pytest.mark.parametrize("network", [True, False])
def test_query_tx_with_koios_empty_hashes(requests_mock, network):
    fake_response = BAD_RESPONSE  # Mock response data
    subdomain = "api" if network else "preprod"
    url = f'https://{subdomain}.koios.rest/api/v0/tx_info'
    requests_mock.post(url, json=fake_response)

    response = query_tx_with_koios([], network)
    assert response == fake_response, "Response does not match expected mock data"


@pytest.mark.parametrize("network", [True, False])
def test_query_tx_with_koios_invalid_hashes(requests_mock, network):
    fake_response = BAD_RESPONSE  # Mock response data
    subdomain = "api" if network else "preprod"
    url = f'https://{subdomain}.koios.rest/api/v0/tx_info'
    requests_mock.post(url, json=fake_response)

    response = query_tx_with_koios(["acab"], network)
    assert response == fake_response, "Response does not match expected mock data"


@pytest.mark.parametrize("network", [True, False])
def test_query_tx_with_koios_no_list_hashes(requests_mock, network):
    fake_response = ERROR_RESPONSE  # Mock response data
    subdomain = "api" if network else "preprod"
    url = f'https://{subdomain}.koios.rest/api/v0/tx_info'
    requests_mock.post(url, json=fake_response)

    response = query_tx_with_koios("acab", network)
    assert response == fake_response, "Response does not match expected mock data"


@pytest.mark.parametrize("network", [True, False])
def test_query_tx_with_koios_numbered_hashes(requests_mock, network):
    fake_response = ERROR_RESPONSE  # Mock response data
    subdomain = "api" if network else "preprod"
    url = f'https://{subdomain}.koios.rest/api/v0/tx_info'
    requests_mock.post(url, json=fake_response)

    response = query_tx_with_koios([1, 2, 3], network)
    assert response == fake_response, "Response does not match expected mock data"