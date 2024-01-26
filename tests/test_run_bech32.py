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


def test_pkh_pkh_run_bech32():
    key, flag = run_bech32("addr_test1qrvnxkaylr4upwxfxctpxpcumj0fl6fdujdc72j8sgpraa9l4gu9er4t0w7udjvt2pqngddn6q4h8h3uv38p8p9cq82qav4lmp")
    assert flag is False
    assert key == "d9335ba4f8ebc0b8c9361613071cdc9e9fe92de49b8f2a4782023ef4bfaa385c8eab7bbdc6c98b50413435b3d02b73de3c644e1384b801d4"


def test_pkh_sc_run_bech32():
    key, flag = run_bech32("addr_test1yrn0s4chhye83r3mretmz85l30cep5jhc47ndxtecx9q9hd77kxf9f4azcy30z8zufp39mkgzqvg6vyjfsgqflsaxxqq2wrsml")
    assert flag is True
    assert key == "e6f85717b932788e3b1e57b11e9f8bf190d257c57d369979c18a02ddbef58c92a6bd16091788e2e24312eec810188d30924c1004fe1d3180"


def test_sc_sc_run_bech32():
    key, flag = run_bech32("addr_test1xrfyfld9zgvy32nsadk4nc0g4svhxp9q7lr6qsve5qjyls977kxf9f4azcy30z8zufp39mkgzqvg6vyjfsgqflsaxxqqcqlkvn")
    assert flag is True
    assert key == "d244fda5121848aa70eb6d59e1e8ac197304a0f7c7a04199a0244fc0bef58c92a6bd16091788e2e24312eec810188d30924c1004fe1d3180"


def test_pkh_run_bech32():
    key, flag = run_bech32("addr_test1vz8hkr8zsw5jm7drk6dvpw83pk9u308cl0gluujedm5t6mq4jwa2p")
    assert flag is False
    assert key == "8f7b0ce283a92df9a3b69ac0b8f10d8bc8bcf8fbd1fe72596ee8bd6c"


def test_sc_pkh_run_bech32():
    key, flag = run_bech32("addr_test1zrfyfld9zgvy32nsadk4nc0g4svhxp9q7lr6qsve5qjyls9l4gu9er4t0w7udjvt2pqngddn6q4h8h3uv38p8p9cq82qk3v3ac")
    assert flag is False
    assert key == "d244fda5121848aa70eb6d59e1e8ac197304a0f7c7a04199a0244fc0bfaa385c8eab7bbdc6c98b50413435b3d02b73de3c644e1384b801d4"
