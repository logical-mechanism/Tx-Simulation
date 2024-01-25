import pytest

from tx_simulation import run_bech32


def test_to_bytes_with_invalid_hex2():
    # Test with an invalid hexadecimal string
    with pytest.raises(TypeError) as excinfo:
        run_bech32("")
    assert "non-standard format in run_bech32() arg at position 1" in str(excinfo.value), "Incorrect error message for invalid input"


def test_stake_run_bech32_not_contract():
    key, flag = run_bech32("stake_test1uzl65wzu364hh0wxex94qsf5xkeaq2mnmc7xgnsnsjuqr4qruvxwu")
    assert flag is False
    assert key == "bfaa385c8eab7bbdc6c98b50413435b3d02b73de3c644e1384b801d4"


def test_stake_run_bech32_contract():
    key, flag = run_bech32("stake_test17pac0wjxyvftp3yw6u0jfdg6ay6q6x0t4xuucxx5gavqzpqdw9kfm")
    assert flag is True
    assert (key == "7b87ba462312b0c48ed71f24b51ae9340d19eba9b9cc18d447580104")


def test_address_run_bech32():
    key, flag = run_bech32("addr_test1qrvnxkaylr4upwxfxctpxpcumj0fl6fdujdc72j8sgpraa9l4gu9er4t0w7udjvt2pqngddn6q4h8h3uv38p8p9cq82qav4lmp")
    assert flag is True
    assert key == "d9335ba4f8ebc0b8c9361613071cdc9e9fe92de49b8f2a4782023ef4bfaa385c8eab7bbdc6c98b50413435b3d02b73de3c644e1384b801d4"
