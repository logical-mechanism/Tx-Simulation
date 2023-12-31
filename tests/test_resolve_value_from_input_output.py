from tx_simulation import resolve_value_from_input_output, to_bytes


def test_resolve_value_from_input_output_empty():
    value = resolve_value_from_input_output(0, [])
    assert value == 0


def test_resolve_value_from_input_output_just_lovelace():
    value = resolve_value_from_input_output(10, [])
    assert value == 10


def test_resolve_value_from_input_output_one_token():
    tokens = [{"policy_id": "acab", "asset_name": "cafe", "quantity": 1}]
    value = resolve_value_from_input_output(10, tokens)
    expected_value = {to_bytes("acab"): {to_bytes("cafe"): 1}}
    assert value == [10, expected_value]


def test_resolve_value_from_input_output_many_token():
    tokens = [
        {"policy_id": "acab", "asset_name": "cafe", "quantity": 1},
        {"policy_id": "acab", "asset_name": "beef", "quantity": 1},
        {"policy_id": "fade", "asset_name": "cafe", "quantity": 100}
    ]

    value = resolve_value_from_input_output(10, tokens)
    expected_tokens = {
        to_bytes("acab"): {
            to_bytes("cafe"): 1,
            to_bytes("beef"): 1
        },
        to_bytes("fade"): {
            to_bytes("cafe"): 100,
        }
    }
    assert value == [10, expected_tokens]


def test_resolve_value_from_input_output_many_same_token():
    tokens = [
        {"policy_id": "acab", "asset_name": "cafe", "quantity": 1},
        {"policy_id": "acab", "asset_name": "cafe", "quantity": 1},
        {"policy_id": "fade", "asset_name": "cafe", "quantity": 100}
    ]

    value = resolve_value_from_input_output(10, tokens)
    expected_tokens = {
        to_bytes("acab"): {
            to_bytes("cafe"): 2,
        },
        to_bytes("fade"): {
            to_bytes("cafe"): 100,
        }
    }
    assert value == [10, expected_tokens]


def test_resolve_value_from_input_output_mint_burn_token():
    tokens = [
        {"policy_id": "acab", "asset_name": "cafe", "quantity": 1},
        {"policy_id": "acab", "asset_name": "cafe", "quantity": -1},
        {"policy_id": "fade", "asset_name": "cafe", "quantity": 100}
    ]

    value = resolve_value_from_input_output(10, tokens)
    expected_tokens = {
        to_bytes("fade"): {
            to_bytes("cafe"): 100,
        }
    }
    assert value == [10, expected_tokens]
