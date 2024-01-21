#!/bin/bash
set -e

# SET UP VARS HERE
source .env

# get params
${cli} query protocol-parameters ${network} --out-file tmp/protocol.json

stake_key="stake_test1uzl65wzu364hh0wxex94qsf5xkeaq2mnmc7xgnsnsjuqr4qruvxwu"

# contracts
always_false_script_path="../contracts/always_false_contract.plutus"
always_false_script_address=$(${cli} address build --payment-script-file ${always_false_script_path} ${network})

always_true_script_path="../contracts/always_true_contract.plutus"
always_true_script_address=$(${cli} address build --payment-script-file ${always_true_script_path} ${network})

lock_script_path="../contracts/lock_contract.plutus"
lock_script_address=$(${cli} address build --payment-script-file ${lock_script_path} --stake-address ${stake_key} ${network})

subtract_fee_script_path="../contracts/subtract_fee_contract.plutus"
subtract_fee_script_address=$(${cli} address build --payment-script-file ${subtract_fee_script_path} ${network})

# user wallet
user_address=$(cat wallets/user-wallet/payment.addr)
user_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/user-wallet/payment.vkey)

echo -e "\033[0;36m Gathering User UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${user_address} \
    --out-file tmp/user_utxo.json

TXNS=$(jq length tmp/user_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${user_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/user_utxo.json)
user_tx_in=${TXIN::-8}


# prep all the utxos
echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file tmp/tx.draft \
    --change-address ${user_address} \
    --tx-in ${user_tx_in} \
    --tx-out="${always_false_script_address} + 3000000" \
    --tx-out-inline-datum-file data/empty-datum.json \
    --tx-out="${always_true_script_address} + 3000000" \
    --tx-out-inline-datum-file data/empty-datum.json \
    --tx-out="${lock_script_address} + 3000000" \
    --tx-out-inline-datum-file data/lock-datum.json \
    --tx-out="${subtract_fee_script_address} + 3000000" \
    --tx-out-inline-datum-file data/lock-datum.json \
    --required-signer-hash ${user_pkh} \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
FEE=${FEE[1]}
echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file wallets/user-wallet/payment.skey \
    --tx-body-file tmp/tx.draft \
    --out-file tmp/tx.signed \
    ${network}
#    
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file tmp/tx.signed

tx=$(cardano-cli transaction txid --tx-file tmp/tx.signed)
echo "Tx Hash:" $tx