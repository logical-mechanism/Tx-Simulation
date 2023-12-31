#!/bin/bash
set -e

# SET UP VARS HERE
source .env

# get params
${cli} query protocol-parameters ${network} --out-file tmp/protocol.json


# contracts
always_false_script_path="../contracts/always_false_contract.plutus"
always_false_script_address=$(${cli} address build --payment-script-file ${always_false_script_path} ${network})

always_true_script_path="../contracts/always_true_contract.plutus"
always_true_script_address=$(${cli} address build --payment-script-file ${always_true_script_path} ${network})

lock_script_path="../contracts/lock_contract.plutus"
lock_script_address=$(${cli} address build --payment-script-file ${lock_script_path} ${network})

subtract_fee_script_path="../contracts/subtract_fee_contract.plutus"
subtract_fee_script_address=$(${cli} address build --payment-script-file ${subtract_fee_script_path} ${network})

single_shot_script_path="../contracts/single_shot_contract.plutus"
single_shot_script_address=$(${cli} address build --payment-script-file ${single_shot_script_path} ${network})

staking_script_path="../contracts/stake_contract.plutus"
staking_script_address=$(${cli} address build --payment-script-file ${staking_script_path} ${network})

# get script utxo
echo -e "\033[0;36m Gathering Always False UTxO Information  \033[0m"
${cli} query utxo \
    --address ${always_false_script_address} \
    ${network} \
    --out-file ./tmp/script_utxo.json
TXNS=$(jq length ./tmp/script_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${always_false_script_address} \033[0m \n";
.   exit;
fi
always_false_tx_in=$(jq -r 'keys[0]' ./tmp/script_utxo.json)

echo -e "\033[0;36m Gathering Always True UTxO Information  \033[0m"
${cli} query utxo \
    --address ${always_true_script_address} \
    ${network} \
    --out-file ./tmp/script_utxo.json
TXNS=$(jq length ./tmp/script_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${always_true_script_address} \033[0m \n";
.   exit;
fi
always_true_tx_in=$(jq -r 'keys[0]' ./tmp/script_utxo.json)

echo -e "\033[0;36m Gathering Lock UTxO Information  \033[0m"
${cli} query utxo \
    --address ${lock_script_address} \
    ${network} \
    --out-file ./tmp/script_utxo.json
TXNS=$(jq length ./tmp/script_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${lock_script_address} \033[0m \n";
.   exit;
fi
lock_tx_in=$(jq -r 'keys[0]' ./tmp/script_utxo.json)

echo -e "\033[0;36m Gathering Subtract Fee UTxO Information  \033[0m"
${cli} query utxo \
    --address ${subtract_fee_script_address} \
    ${network} \
    --out-file ./tmp/script_utxo.json
TXNS=$(jq length ./tmp/script_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${subtract_fee_script_address} \033[0m \n";
.   exit;
fi
subtract_fee_tx_in=$(jq -r 'keys[0]' ./tmp/script_utxo.json)

# wallets
user_address=$(cat wallets/user-wallet/payment.addr)
user_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/user-wallet/payment.vkey)

minter_address=$(cat wallets/minter-wallet/payment.addr)
minter_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/minter-wallet/payment.vkey)

collat_address=$(cat wallets/collat-wallet/payment.addr)
collat_pkh=$(${cli} address key-hash --payment-verification-key-file wallets/collat-wallet/payment.vkey)

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

echo -e "\033[0;36m Gathering Minter UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${minter_address} \
    --out-file tmp/minter_utxo.json

TXNS=$(jq length tmp/minter_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${minter_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/minter_utxo.json)
minter_tx_in=${TXIN::-8}

echo -e "\033[0;36m Gathering Collat UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${collat_address} \
    --out-file tmp/collat_utxo.json

TXNS=$(jq length tmp/collat_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${collat_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' tmp/collat_utxo.json)
collat_tx_in=${TXIN::-8}

# script references

echo -e "\033[0;36m Building Lock Tx \033[0m"
lock_ref_utxo=$(${cli} transaction txid --tx-file ./tmp/tx-lock_contract.plutus.signed )
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file ./tmp/tx.draft \
    --change-address ${user_address} \
    --tx-in-collateral ${collat_tx_in} \
    --tx-in ${user_tx_in} \
    --tx-in ${lock_tx_in} \
    --spending-tx-in-reference="${lock_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --tx-out="${user_address} + 3000000" \
    --required-signer-hash ${user_pkh} \
    --required-signer-hash ${collat_pkh} \
    ${network})

jq -r '.cborHex' ./tmp/tx.draft > cbor/lock.cbor


# build out all the cbors
echo -e "\033[0;36m Building Always True Tx \033[0m"
always_true_ref_utxo=$(${cli} transaction txid --tx-file ./tmp/tx-always_true_contract.plutus.signed )
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file ./tmp/tx.draft \
    --change-address ${user_address} \
    --tx-in-collateral ${collat_tx_in} \
    --tx-in ${user_tx_in} \
    --tx-in ${always_true_tx_in} \
    --spending-tx-in-reference="${always_true_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --required-signer-hash ${collat_pkh} \
    ${network})

jq -r '.cborHex' ./tmp/tx.draft > cbor/always_true.cbor


echo -e "\033[0;36m Building Single Shot Tx \033[0m"
tx_id_hash=$(jq -r '.tx_id_hash' ../start_info.json)
tx_id_idx=$(jq -r '.tx_id_idx' ../start_info.json)
nft_prefix=""
nft_pid=$(cat ../hashes/single_shot.hash)
nft_tkn=$(python3 -c "import sys; sys.path.append('py/'); from unique_token_name import token_name; token_name('${tx_id_hash}', ${tx_id_idx}, '${nft_prefix}')")

mint_asset="1 ${nft_pid}.${nft_tkn}"
single_shot_ref_utxo=$(${cli} transaction txid --tx-file ./tmp/tx-single_shot_contract.plutus.signed )
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file tmp/tx.draft \
    --change-address ${minter_address} \
    --tx-in-collateral="${collat_tx_in}" \
    --tx-in ${minter_tx_in} \
    --required-signer-hash ${collat_pkh} \
    --mint="${mint_asset}" \
    --mint-tx-in-reference="${single_shot_ref_utxo}#1" \
    --mint-plutus-script-v2 \
    --policy-id="${nft_pid}" \
    --mint-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    ${network})

jq -r '.cborHex' ./tmp/tx.draft > cbor/single_shot.cbor


# build out all the cbors
echo -e "\033[0;36m Building Always False Tx \033[0m"
always_false_ref_utxo=$(${cli} transaction txid --tx-file ./tmp/tx-always_false_contract.plutus.signed )
cpu_steps=0
mem_steps=0
execution_unts="(${cpu_steps}, ${mem_steps})"

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in-collateral="${collat_tx_in}" \
    --tx-in ${user_tx_in} \
    --tx-in ${always_false_tx_in} \
    --spending-tx-in-reference="${always_false_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-execution-units="${execution_unts}" \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --tx-out="${user_address} + 3000000" \
    --required-signer-hash ${collat_pkh} \
    --fee 400000


jq -r '.cborHex' ./tmp/tx.draft > cbor/always_false.cbor

# build out all the cbors
echo -e "\033[0;36m Building Subtract Fee Tx \033[0m"
subtract_fee_ref_utxo=$(${cli} transaction txid --tx-file ./tmp/tx-subtract_fee_contract.plutus.signed )
cpu_steps=0
mem_steps=0
execution_unts="(${cpu_steps}, ${mem_steps})"

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in-collateral="${collat_tx_in}" \
    --tx-in ${user_tx_in} \
    --tx-in ${subtract_fee_tx_in} \
    --spending-tx-in-reference="${subtract_fee_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-execution-units="${execution_unts}" \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --tx-out="${user_address} + 2000000" \
    --required-signer-hash ${user_pkh} \
    --required-signer-hash ${collat_pkh} \
    --fee 1000000


jq -r '.cborHex' ./tmp/tx.draft > cbor/subtract_fee.cbor


echo -e "\033[0;36m Building Multi Contract Tx \033[0m"
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file ./tmp/tx.draft \
    --change-address ${user_address} \
    --tx-in-collateral ${collat_tx_in} \
    --tx-in ${user_tx_in} \
    --tx-in ${always_true_tx_in} \
    --spending-tx-in-reference="${always_true_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --tx-in ${lock_tx_in} \
    --spending-tx-in-reference="${lock_ref_utxo}#1" \
    --spending-plutus-script-v2 \
    --spending-reference-tx-in-inline-datum-present \
    --spending-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --tx-out="${user_address} + 3000000" \
    --tx-in ${minter_tx_in} \
    --required-signer-hash ${collat_pkh} \
    --mint="${mint_asset}" \
    --mint-tx-in-reference="${single_shot_ref_utxo}#1" \
    --mint-plutus-script-v2 \
    --policy-id="${nft_pid}" \
    --mint-reference-tx-in-redeemer-file ./data/empty-redeemer.json \
    --required-signer-hash ${collat_pkh} \
    --required-signer-hash ${user_pkh} \
    --required-signer-hash ${minter_pkh} \
    ${network})


jq -r '.cborHex' ./tmp/tx.draft > cbor/multi.cbor