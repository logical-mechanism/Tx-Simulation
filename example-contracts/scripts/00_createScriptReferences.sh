#!/usr/bin/env bash
set -e

# SET UP VARS HERE
source .env

mkdir -p ./tmp
${cli} query protocol-parameters ${network} --out-file ./tmp/protocol.json

# contract path
dao_script_path="../contracts/dao_contract.plutus"
genesis_script_path="../contracts/genesis_contract.plutus"
oracle_script_path="../contracts/oracle_contract.plutus"
drep_mint_script_path="../contracts/drep_mint_contract.plutus"
drep_lock_script_path="../contracts/drep_lock_contract.plutus"
vault_script_path="../contracts/vault_contract.plutus"

# Addresses
reference_address=$(cat ./wallets/reference-wallet/payment.addr)
script_reference_address=$(cat ./wallets/reference-wallet/payment.addr)

# dao
dao_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${dao_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

dao_value=$((${dao_min_utxo}))
dao_script_reference_utxo="${script_reference_address} + ${dao_value}"

# genesis
genesis_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${genesis_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

genesis_value=$((${genesis_min_utxo}))
genesis_script_reference_utxo="${script_reference_address} + ${genesis_value}"

# oracle
oracle_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${oracle_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

oracle_value=$((${oracle_min_utxo}))
oracle_script_reference_utxo="${script_reference_address} + ${oracle_value}"

# drep mint
drep_mint_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${drep_mint_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

drep_mint_value=$((${drep_mint_min_utxo}))
drep_mint_script_reference_utxo="${script_reference_address} + ${drep_mint_value}"


# drep lock
drep_lock_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${drep_lock_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

drep_lock_value=$((${drep_lock_min_utxo}))
drep_lock_script_reference_utxo="${script_reference_address} + ${drep_lock_value}"

# vault
vault_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --tx-out-reference-script-file ${vault_script_path} \
    --tx-out="${script_reference_address} + 1000000" | tr -dc '0-9')

vault_value=$((${vault_min_utxo}))
vault_script_reference_utxo="${script_reference_address} + ${vault_value}"

# print them out
echo -e "\nCreating DAO Script:\n" ${dao_script_reference_utxo}
echo -e "\nCreating Genesis Script:\n" ${genesis_script_reference_utxo}
echo -e "\nCreating Oracle Script:\n" ${oracle_script_reference_utxo}
echo -e "\nCreating dRep Mint Script:\n" ${drep_mint_script_reference_utxo}
echo -e "\nCreating dRep Lock Script:\n" ${drep_lock_script_reference_utxo}
echo -e "\nCreating dRep Lock Script:\n" ${vault_script_reference_utxo}
#
# exit
#
echo -e "\033[0;35m\nGathering UTxO Information  \033[0m"
${cli} query utxo \
    ${network} \
    --address ${reference_address} \
    --out-file ./tmp/reference_utxo.json

TXNS=$(jq length ./tmp/reference_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${reference_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'to_entries[] | select(.value.value | length < 2) | .key | . + $alltxin + " --tx-in"' ./tmp/reference_utxo.json)
ref_tx_in=${TXIN::-8}
#
# exit
#
###############################################################################
# chain second set of reference scripts to the first
echo -e "\033[0;33m\nStart Building Tx Chain \033[0m"
echo -e "\033[0;36m Building Tx \033[0m"
starting_reference_lovelace=$(jq '[.. | objects | .lovelace] | add' ./tmp/reference_utxo.json)

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in ${ref_tx_in} \
    --tx-out="${reference_address} + ${starting_reference_lovelace}" \
    --tx-out="${dao_script_reference_utxo}" \
    --tx-out-reference-script-file ${dao_script_path} \
    --fee 900000

FEE=$(cardano-cli transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

#
firstReturn=$((${starting_reference_lovelace} - ${dao_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in ${ref_tx_in} \
    --tx-out="${reference_address} + ${firstReturn}" \
    --tx-out="${dao_script_reference_utxo}" \
    --tx-out-reference-script-file ${dao_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-1.signed \
    ${network}

###############################################################################

nextUTxO=$(${cli} transaction txid --tx-body-file ./tmp/tx.draft)
echo "First in the tx chain" $nextUTxO

echo -e "\033[0;36m Building Tx \033[0m"
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${firstReturn}" \
    --tx-out="${genesis_script_reference_utxo}" \
    --tx-out-reference-script-file ${genesis_script_path} \
    --fee 900000

FEE=$(${cli} transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

secondReturn=$((${firstReturn} - ${genesis_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${secondReturn}" \
    --tx-out="${genesis_script_reference_utxo}" \
    --tx-out-reference-script-file ${genesis_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-2.signed \
    ${network}
###############################################################################

nextUTxO=$(${cli} transaction txid --tx-body-file ./tmp/tx.draft)
echo "Second in the tx chain" $nextUTxO

echo -e "\033[0;36m Building Tx \033[0m"
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${secondReturn}" \
    --tx-out="${oracle_script_reference_utxo}" \
    --tx-out-reference-script-file ${oracle_script_path} \
    --fee 900000

FEE=$(${cli} transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

thirdReturn=$((${secondReturn} - ${oracle_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${thirdReturn}" \
    --tx-out="${oracle_script_reference_utxo}" \
    --tx-out-reference-script-file ${oracle_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-3.signed \
    ${network}
###############################################################################

nextUTxO=$(${cli} transaction txid --tx-body-file ./tmp/tx.draft)
echo "Third in the tx chain" $nextUTxO

echo -e "\033[0;36m Building Tx \033[0m"
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${thirdReturn}" \
    --tx-out="${drep_mint_script_reference_utxo}" \
    --tx-out-reference-script-file ${drep_mint_script_path} \
    --fee 900000

FEE=$(${cli} transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

fourthReturn=$((${thirdReturn} - ${drep_mint_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${fourthReturn}" \
    --tx-out="${drep_mint_script_reference_utxo}" \
    --tx-out-reference-script-file ${drep_mint_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-4.signed \
    ${network}
###############################################################################

nextUTxO=$(${cli} transaction txid --tx-body-file ./tmp/tx.draft)
echo "Fourth in the tx chain" $nextUTxO

echo -e "\033[0;36m Building Tx \033[0m"
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${fourthReturn}" \
    --tx-out="${drep_lock_script_reference_utxo}" \
    --tx-out-reference-script-file ${drep_lock_script_path} \
    --fee 900000

FEE=$(${cli} transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

fifthReturn=$((${fourthReturn} - ${drep_lock_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${fifthReturn}" \
    --tx-out="${drep_lock_script_reference_utxo}" \
    --tx-out-reference-script-file ${drep_lock_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-5.signed \
    ${network}
###############################################################################


nextUTxO=$(${cli} transaction txid --tx-body-file ./tmp/tx.draft)
echo "Fifth in the tx chain" $nextUTxO

echo -e "\033[0;36m Building Tx \033[0m"
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${fifthReturn}" \
    --tx-out="${vault_script_reference_utxo}" \
    --tx-out-reference-script-file ${vault_script_path} \
    --fee 900000

FEE=$(${cli} transaction calculate-min-fee --tx-body-file ./tmp/tx.draft ${network} --protocol-params-file ./tmp/protocol.json --tx-in-count 1 --tx-out-count 2 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)

sixthReturn=$((${fifthReturn} - ${vault_value} - ${fee}))

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ./tmp/protocol.json \
    --out-file ./tmp/tx.draft \
    --tx-in="${nextUTxO}#0" \
    --tx-out="${reference_address} + ${sixthReturn}" \
    --tx-out="${vault_script_reference_utxo}" \
    --tx-out-reference-script-file ${vault_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ./wallets/reference-wallet/payment.skey \
    --tx-body-file ./tmp/tx.draft \
    --out-file ./tmp/tx-6.signed \
    ${network}
###############################################################################

#
# exit
#
echo -e "\033[0;34m\nSubmitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-1.signed

${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-2.signed

${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-3.signed

${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-4.signed

${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-5.signed

${cli} transaction submit \
    ${network} \
    --tx-file ./tmp/tx-6.signed
###############################################################################

cp ./tmp/tx-1.signed ./tmp/dao-reference-utxo.signed
cp ./tmp/tx-2.signed ./tmp/genesis-reference-utxo.signed
cp ./tmp/tx-3.signed ./tmp/oracle-reference-utxo.signed
cp ./tmp/tx-4.signed ./tmp/drep-mint-reference-utxo.signed
cp ./tmp/tx-5.signed ./tmp/drep-lock-reference-utxo.signed
cp ./tmp/tx-6.signed ./tmp/vault-reference-utxo.signed

echo -e "\033[0;32m\nDone!\033[0m"
