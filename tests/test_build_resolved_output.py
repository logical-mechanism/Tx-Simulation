from tx_simulation import build_resolved_output, resolve_inputs_and_outputs


def test_build_resolved_outputs():
    resolved = {}
    network = False
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = '84a900828258200b5d93ee6482f42a2e5d21d8d5496b2e7e09dce787d4ed5401fed153af08d7b600825820589a17a9fba2c3fd4a4ef324ea7cc6d37b0d03314a25e04147f4f7dacc1a4f1b010d818258206e34390c14ea8041c85963cf4b00a4ac900ebfd4e7bbcc9df7ed9345393777f30012828258208f457077d56938420978dd2c47f1cf8cc0f5e0339b8e066b9c4ca63df086e15e01825820f60de32b7cf065e9f182d701078f0b310b965abdb5ca0cc24eb18dc4271c961d000182a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc01821a00400ed4a2581c015d83f25700c83d708fbf8ad57783dc257b01a932ffceac9dcd0c3da14843757272656e63791a001e8480581c698a6ea0ca99f315034072af31eaac6ec11fe8558d3f48e9775aab9da14574445249501a000f4240a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc011a76c2f34a10a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc011a00932570111a00057110021a0003a0b50e82581c2d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc581cb834fb41c45bd80e5fd9d99119723637fe9d1e3fc467bc1c57ae9aee0b5820a25626d921a18ec23871bed8e6173d36cd73dbfae748fa96d7bf76f72e95b292a10581840000d87b80821a0006c5081a0a3a6c3df5f6'
    inputs, resolved_inputs_outputs = resolve_inputs_and_outputs(valid_hex_cbor, network)
    # the order of the resolved outputs matter so we match to the inputs
    input_tx_hash = inputs[0][0]
    input_tx_idx = inputs[0][1]
    # now find the input output for that hash
    for tx_input_output in resolved_inputs_outputs:
        that_tx_hash = tx_input_output['tx_hash']
        if input_tx_hash != that_tx_hash:
            # have to match the hashes so the we can resolve a specific tx input
            continue

        # now we have a tx input output for a given input
        resolved = build_resolved_output(input_tx_hash, input_tx_idx, tx_input_output, network)
        break
    assert 0 in resolved
    assert 1 in resolved


def test_build_resolved_outputs_wrong_network():
    resolved = {}
    network = True
    # Replace 'valid_hex_cbor' with a valid hexadecimal string representing CBOR data
    valid_hex_cbor = '84a900828258200b5d93ee6482f42a2e5d21d8d5496b2e7e09dce787d4ed5401fed153af08d7b600825820589a17a9fba2c3fd4a4ef324ea7cc6d37b0d03314a25e04147f4f7dacc1a4f1b010d818258206e34390c14ea8041c85963cf4b00a4ac900ebfd4e7bbcc9df7ed9345393777f30012828258208f457077d56938420978dd2c47f1cf8cc0f5e0339b8e066b9c4ca63df086e15e01825820f60de32b7cf065e9f182d701078f0b310b965abdb5ca0cc24eb18dc4271c961d000182a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc01821a00400ed4a2581c015d83f25700c83d708fbf8ad57783dc257b01a932ffceac9dcd0c3da14843757272656e63791a001e8480581c698a6ea0ca99f315034072af31eaac6ec11fe8558d3f48e9775aab9da14574445249501a000f4240a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc011a76c2f34a10a200581d602d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc011a00932570111a00057110021a0003a0b50e82581c2d5fec7bbb8abbe1fb6590db2676389dffab196d212fb2b4b9902dcc581cb834fb41c45bd80e5fd9d99119723637fe9d1e3fc467bc1c57ae9aee0b5820a25626d921a18ec23871bed8e6173d36cd73dbfae748fa96d7bf76f72e95b292a10581840000d87b80821a0006c5081a0a3a6c3df5f6'
    inputs, resolved_inputs_outputs = resolve_inputs_and_outputs(valid_hex_cbor, network)
    # the order of the resolved outputs matter so we match to the inputs
    input_tx_hash = inputs[0][0]
    input_tx_idx = inputs[0][1]
    # now find the input output for that hash
    for tx_input_output in resolved_inputs_outputs:
        that_tx_hash = tx_input_output['tx_hash']
        if input_tx_hash != that_tx_hash:
            # have to match the hashes so the we can resolve a specific tx input
            continue

        # now we have a tx input output for a given input
        resolved = build_resolved_output(input_tx_hash, input_tx_idx, tx_input_output, network)
        break
    assert not resolved
