import binascii
import hashlib


def token_name(txHash: str, index: int, prefix: str) -> str:
    """
    Generate a token name based on a transaction hash, an index, and a prefix.

    Args:
    txHash (str): The transaction hash as a hexadecimal string.
    index (int): An integer index used in generating the token name.
    prefix (str): A string prefix for the token name.

    Returns:
    str: The generated token name.
    """
    # Convert the hexadecimal transaction hash to bytes
    txBytes = binascii.unhexlify(txHash)

    # Create a new SHA3-256 hash object
    h = hashlib.new('sha3_256')
    # Update the hash object with the transaction bytes
    h.update(txBytes)

    # Get the hexadecimal digest of the hash
    txHash = h.hexdigest()

    # Convert the index to hexadecimal and take the last two characters
    x = hex(index)[-2:]

    # Replace 'x' with '0' if present in the hexadecimal representation
    if "x" in x:
        x = x.replace("x", "0")

    # Construct the final token name by concatenating prefix, modified index, and hash
    txHash = prefix + x + txHash

    # Print and return the first 64 characters of the token name
    print(txHash[0:64])
    return txHash[0:64]

# Example usage
# token_name("your_tx_hash_here", 1, "prefix")

