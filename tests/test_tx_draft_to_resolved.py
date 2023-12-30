import pytest

from tx_simulation import tx_draft_to_resolved_cbor


def test_tx_draft_to_resolved_cbor_empty_string():
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = '40'
    expected_result = b''
    assert tx_draft_to_resolved_cbor(valid_hex_cbor) == expected_result, "Failed to decode valid CBOR data"


def test_tx_draft_to_resolved_cbor_valid1():
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = '84A3008182582074686973206973206120737472696E6720696E73696465207468652063626F720001800200A0F5F6'
    expected_result = [{0: [[b'this is a string inside the cbor', 0]], 1: [], 2: 0}, {}, True, None]
    assert tx_draft_to_resolved_cbor(valid_hex_cbor) == expected_result, "Failed to decode valid CBOR data"


def test_tx_draft_to_resolved_cbor_true_is_true():
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = 'F5'
    expected_result = True
    assert tx_draft_to_resolved_cbor(valid_hex_cbor) == expected_result, "Failed to decode valid CBOR data"


def test_tx_draft_to_resolved_cbor_false_is_false():
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = 'F4'
    expected_result = False
    assert tx_draft_to_resolved_cbor(valid_hex_cbor) == expected_result, "Failed to decode valid CBOR data"


def test_tx_draft_to_resolved_cbor_null_is_none():
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = 'F6'
    expected_result = None
    assert tx_draft_to_resolved_cbor(valid_hex_cbor) == expected_result, "Failed to decode valid CBOR data"


def test_tx_draft_to_resolved_cbor_invalid_hex():
    with pytest.raises(ValueError) as excinfo:
        tx_draft_to_resolved_cbor('not_a_hex')
    assert "non-hexadecimal number found in fromhex() arg at position 1" in str(excinfo.value), "Incorrect error message for invalid hex"
