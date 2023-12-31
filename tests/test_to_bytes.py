import pytest

from tx_simulation import to_bytes


def test_empty_to_bytes():
    assert to_bytes("") == b""


def test_number_to_bytes():
    assert to_bytes("30") == b'0'


def test_to_bytes_with_valid_hex():
    # Test with a valid hexadecimal string
    assert to_bytes("68656c6c6f") == b'hello', "Failed to convert valid hex string to bytes"


def test_to_bytes_with_invalid_hex1():
    # Test with an invalid hexadecimal string
    with pytest.raises(ValueError) as excinfo:
        to_bytes(hex(1))
    assert "non-hexadecimal number found in fromhex() arg at position 1" in str(excinfo.value), "Incorrect error message for invalid hex"


def test_to_bytes_with_invalid_hex2():
    # Test with an invalid hexadecimal string
    with pytest.raises(ValueError) as excinfo:
        to_bytes("not a hex")
    assert "non-hexadecimal number found in fromhex() arg at position 1" in str(excinfo.value), "Incorrect error message for invalid hex"


def test_long_string_to_bytes():
    assert to_bytes("0b5d93ee6482f42a2e5d21d8d5496b2e7e09dce787d4ed5401fed153af08d7b6").hex() == "0b5d93ee6482f42a2e5d21d8d5496b2e7e09dce787d4ed5401fed153af08d7b6"
