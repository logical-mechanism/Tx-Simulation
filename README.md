# tx_simulation

The `tx_simulation` tool facilitates transaction simulation using `aiken tx simulate` in conjunction with Koios. 

The simulation script assumes the contracts are implemented using PlutusV2, relies on reference script UTxOs, and operates under the assumption that within a transaction, only the scripts themselves contain datums. It's important to note that specific edge cases may need to be considered when transitioning to a production environment. Additionally, the simulation script currently supports both the mainnet and pre-production environments but does not provide support for preview environments at this time.

The tx simulation script was tested with `Python 3.10.12`, `Aiken v1.0.21`, and `Ubuntu 22.04.2 LTS`.

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

# On Windows, use: 
# venv\Scripts\activate

# Install required Python packages
pip install -r requirements.txt
```

## Use

The `tx_simulation` script can simulate a transaction from a draft file or from pure cbor.

```bash
import tx_simulation

# can be used on a tx.draft file
required_units = tx_simulation.from_file('tx.draft')

# can be used directory on the tx cbor
required_units = tx_simulation.from_cbor(tx_cbor)
```

It will either return a list of dictionaries of the units or a list with an empty dict if it fails. An output example is shown below.

Success example
```json
[{
    "mem": 443656, 
    "cpu": 171399581
}]
```

Failure example
```json
[{}]
```

## Testing

Inside the `tests` folder are pytest tests for `tx_simulation.py`. The tests can be ran with the command below.

```bash
pytest
```

## Known Issues

Any scripts involving fee logic always error resulting in an empty dictionary being returned.