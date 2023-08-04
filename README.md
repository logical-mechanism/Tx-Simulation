# tx_simulation

Simulates a transaction using Aiken tx simulate and Koios.

The script assumes PlutusV2, reference scripts, and scripts only have datums. Specific edge cases may need to be accounted for in production.

## Requirements
Aiken needs to be installed and on path.

[Install Aiken](https://aiken-lang.org/installation-instructions)

The script was tested with `Python 3.10.12` and `Ubuntu 22.04.2 LTS`.

```bash
pip install -r requirements.txt
```

## Use

The script can simulate from a tx draft file or from pure tx cbor.

```bash
import tx_simulation

# can be used on a tx.draft file
required_units = tx_simulation.from_file('tx.draft')

# can be used directory on the tx cbor
required_units = tx_simulation.from_cbor(tx_cbor)
```

It will either return a dictionary of the units or the empty dict if it fails. An output example is shown below.

```json
{
    'mem': 443656, 
    'cpu': 171399581
}
```

## Test Data

Inside the `test_data` folder are some example tx drafts. The script can be tested with one of them by running the command below.

```bash
python tx_simulation.py
```

Change which tx draft for different tests.