#!/usr/bin/env bash
set -e

# SET UP VARS HERE
source .env

# get current parameters
mkdir -p ./tmp
${cli} query protocol-parameters ${network} --out-file ./tmp/protocol.json
${cli} query tip ${network} | jq


# Loop through each file in the directory
for contract in "../contracts"/*
do
    echo -e "\033[1;37m --------------------------------------------------------------------------------\033[0m"
    echo -e "\033[1;35m ${contract}\033[0m" 
    script_address=$(${cli} address build --payment-script-file ${contract} ${network})
    echo -e "\n \033[1;35m ${script_address} \033[0m \n";
    file_name=$(basename "$contract")
    ${cli} query utxo --address ${script_address} ${network}
    ${cli} query utxo --address ${script_address} ${network} --out-file ./tmp/current_${file_name}.utxo

    baseLovelace=$(jq '[.. | objects | .lovelace] | add' ./tmp/current_${file_name}.utxo)
    echo -e "\033[0m"

    echo -e "\033[1;36m"
    ada=$(echo "scale = 6;${baseLovelace} / 1000000" | bc -l)
    echo -e "TOTAL ADA:" ${ada}
    echo -e "\033[0m"
done

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
