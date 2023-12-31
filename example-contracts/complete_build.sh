#!/bin/bash
set -e

# create directories if dont exist
mkdir -p contracts
mkdir -p hashes
mkdir -p certs

# remove old files
rm contracts/* || true
rm hashes/* || true
rm certs/* || true

# build out the entire script
echo -e "\033[1;34m\nBuilding Contracts \033[0m"
aiken build

echo -e "\033[1;33m\nBuilding Always False Contract \033[0m"
aiken blueprint convert -v always_false.params > contracts/always_false_contract.plutus
cardano-cli transaction policyid --script-file contracts/always_false_contract.plutus > hashes/always_false.hash
echo -e "\033[1;33m Always False Hash: $(cat hashes/always_false.hash) \033[0m"

echo -e "\033[1;33m\nBuilding Always True Contract \033[0m"
aiken blueprint convert -v always_true.params > contracts/always_true_contract.plutus
cardano-cli transaction policyid --script-file contracts/always_true_contract.plutus > hashes/always_true.hash
echo -e "\033[1;33m Always True Hash: $(cat hashes/always_true.hash) \033[0m"

echo -e "\033[1;33m\nBuilding Lock Contract \033[0m"
aiken blueprint convert -v lock.params > contracts/lock_contract.plutus
cardano-cli transaction policyid --script-file contracts/lock_contract.plutus > hashes/lock.hash
echo -e "\033[1;33m Lock Hash: $(cat hashes/lock.hash) \033[0m"

echo -e "\033[1;33m\nBuilding Single Shot Contract \033[0m"
# the initial utxo for the single shot
tx_id_hash=$(jq -r '.tx_id_hash' start_info.json)
tx_id_hash_cbor=$(python3 -c "import cbor2;hex_string='${tx_id_hash}';data=bytes.fromhex(hex_string);encoded=cbor2.dumps(data);print(encoded.hex())")
tx_id_idx=$(jq -r '.tx_id_idx' start_info.json)
tx_id_idx_cbor=$(python3 -c "import cbor2;encoded=cbor2.dumps(${tx_id_idx});print(encoded.hex())")
aiken blueprint apply -o plutus.json -v single_shot.params "${tx_id_hash_cbor}"
aiken blueprint apply -o plutus.json -v single_shot.params "${tx_id_idx_cbor}"
aiken blueprint convert -v single_shot.params > contracts/single_shot_contract.plutus
cardano-cli transaction policyid --script-file contracts/single_shot_contract.plutus > hashes/single_shot.hash
echo -e "\033[1;33m Single Shot Hash: $(cat hashes/single_shot.hash) \033[0m"

# build the stake contract
echo -e "\033[1;33m\nBuilding Stake Contract \033[0m"
poolId="1e3105f23f2ac91b3fb4c35fa4fe301421028e356e114944e902005b"
aiken blueprint convert -v staking.params > contracts/stake_contract.plutus
cardano-cli stake-address registration-certificate --stake-script-file contracts/stake_contract.plutus --out-file certs/stake.cert
cardano-cli stake-address deregistration-certificate --stake-script-file contracts/stake_contract.plutus --out-file certs/de-stake.cert
cardano-cli stake-address delegation-certificate --stake-script-file contracts/stake_contract.plutus --stake-pool-id ${poolId} --out-file certs/deleg.cert
cardano-cli transaction policyid --script-file contracts/stake_contract.plutus > hashes/stake.hash
echo -e "\033[1;33m Staking Hash: $(cat hashes/stake.hash) \033[0m"

echo -e "\033[1;33m\nBuilding Subtract Fee Contract \033[0m"
aiken blueprint convert -v subtract_fee.params > contracts/subtract_fee_contract.plutus
cardano-cli transaction policyid --script-file contracts/subtract_fee_contract.plutus > hashes/subtract_fee.hash
echo -e "\033[1;33m Subtract Fee Hash: $(cat hashes/subtract_fee.hash) \033[0m"

# end of build
echo -e "\033[1;32m\nBuilding Complete! \033[0m"
