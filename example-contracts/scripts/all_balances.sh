#!/usr/bin/env bash
set -e

# SET UP VARS HERE
source .env

# cip 68 contract
dao_script_path="../contracts/dao_contract.plutus"
dao_script_address=$(${cli} address build --payment-script-file ${dao_script_path} ${network})

# oracle script
oracle_script_path="../contracts/oracle_contract.plutus"
oracle_script_address=$(${cli} address build --payment-script-file ${oracle_script_path} ${network})

# drep lock script
drep_lock_script_path="../contracts/drep_lock_contract.plutus"
drep_lock_script_address=$(${cli} address build --payment-script-file ${drep_lock_script_path} ${network})

# vault
vault_script_path="../contracts/vault_contract.plutus"
vault_script_address=$(${cli} address build --payment-script-file ${vault_script_path} ${network})

# get current parameters
mkdir -p ./tmp
${cli} query protocol-parameters ${network} --out-file ./tmp/protocol.json
${cli} query tip ${network} | jq

# dao
echo -e "\033[1;35m DAO Contract Address: \033[0m" 
echo -e "\n \033[1;35m ${dao_script_address} \033[0m \n";
${cli} query utxo --address ${dao_script_address} ${network}
${cli} query utxo --address ${dao_script_address} ${network} --out-file ./tmp/current_dao.utxo

# oracle
echo -e "\033[1;35m Oracle Contract Address: \033[0m" 
echo -e "\n \033[1;35m ${oracle_script_address} \033[0m \n";
${cli} query utxo --address ${oracle_script_address} ${network}
${cli} query utxo --address ${oracle_script_address} ${network} --out-file ./tmp/current_oracle.utxo

# drep lock
echo -e "\033[1;35m dRep Lock Contract Address: \033[0m" 
echo -e "\n \033[1;35m ${drep_lock_script_address} \033[0m \n";
${cli} query utxo --address ${drep_lock_script_address} ${network}
${cli} query utxo --address ${drep_lock_script_address} ${network} --out-file ./tmp/current_drep.utxo

# vault
echo -e "\033[1;35m Vault Contract Address: \033[0m" 
echo -e "\n \033[1;35m ${vault_script_address} \033[0m \n";
${cli} query utxo --address ${vault_script_address} ${network}
${cli} query utxo --address ${vault_script_address} ${network} --out-file ./tmp/current_vault.utxo

# Loop through each -wallet folder
for wallet_folder in wallets/*-wallet; do
    # Check if payment.addr file exists in the folder
    if [ -f "${wallet_folder}/payment.addr" ]; then
        addr=$(cat ${wallet_folder}/payment.addr)
        echo
        
        echo -e "\033[1;37m --------------------------------------------------------------------------------\033[0m"
        echo -e "\033[1;34m $wallet_folder\033[0m\n\n\033[1;32m $addr\033[0m"
        

        echo -e "\033[1;33m"
        # Run the cardano-cli command with the reference address and testnet magic
        ${cli} query utxo --address ${addr} ${network}
        ${cli} query utxo --address ${addr} ${network} --out-file ./tmp/"${addr}.json"

        baseLovelace=$(jq '[.. | objects | .lovelace] | add' ./tmp/"${addr}.json")
        echo -e "\033[0m"

        echo -e "\033[1;36m"
        ada=$(echo "scale = 6;${baseLovelace} / 1000000" | bc -l)
        echo -e "TOTAL ADA:" ${ada}
        echo -e "\033[0m"
    fi
done
