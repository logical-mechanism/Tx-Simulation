# tx_simulation

The `tx_simulation` tool facilitates transaction simulation using `aiken tx simulate` in conjunction with Koios. 

The simulation script assumes the contracts are implemented using PlutusV2, relies on reference script UTxOs, and operates under the assumption that within a transaction, only the script UTxOs have datums. `tx_simulation` currently supports the mainnet and pre-production environments. Support for the preview environment  is not implemented at this time.

The tx simulation script was tested with `Python 3.10.12`, `Aiken v1.1.0`, and `Ubuntu 22.04.2 LTS`.

## Requirements

It is highly suggested that Aiken is installed and on path.

[Install Aiken](https://aiken-lang.org/installation-instructions)

A precompile version of Aiken may be used with the `from_file` or `from_cbor` functions. 

## Development

It is highly suggested to work on `tx_simulation` inside a virtual environment.

```bash
# Create a Python virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install required Python packages
pip install -r requirements.txt
```

## Use

The `tx_simulation` script can simulate a transaction from a transaction file or from pure cbor.

```py
import tx_simulation

# can be used on a tx.draft file
execution_units = tx_simulation.from_file('path/to/tx.draft')

# can be used directory on the tx cbor
execution_units = tx_simulation.from_cbor(tx_cbor)
```

It will either return a list of dictionaries of the execution units or a list with an empty dict if it fails. An output example is shown below.

Success example:

```json
[{
    "mem": 443656, 
    "cpu": 171399581
}]
```

Failure example:

```json
[{}]
```

## Testing

Inside the `tests` folder are pytest tests for `tx_simulation`. The tests can be ran with the command below.

```bash
pytest
```

