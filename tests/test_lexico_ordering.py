from tx_simulation import get_index_in_order, sort_lexicographically


def test_single_item_is_first():
    x = "9ac0928f338ec0c4f5ae1275fe6517881a9c842c07720097ffc4f5fb82975dc1#0"

    # Get the ordered list of strings
    ordered_list = sort_lexicographically(x)

    # Get and print the index of each string
    index_x = get_index_in_order(ordered_list, x)
    assert index_x == 0


def test_three_unique_items():
    x = "d4c1747f2a6dea8f307f4846dab721798f141aeb156cb24221c5671548e6cf7e#0"
    y = "a1133d386f47a72edd05d964540fe9763552685ca9ffbf07b26770766d063009#0"
    z = "9ac0928f338ec0c4f5ae1275fe6517881a9c842c07720097ffc4f5fb82975dc1#0"

    # Get the ordered list of strings
    ordered_list = sort_lexicographically(x, y, z)

    # Get and print the index of each string
    index_x = get_index_in_order(ordered_list, x)
    index_y = get_index_in_order(ordered_list, y)
    index_z = get_index_in_order(ordered_list, z)
    assert index_x == 2
    assert index_y == 1
    assert index_z == 0


def test_same_id_different_idx():
    x = "d4c1747f2a6dea8f307f4846dab721798f141aeb156cb24221c5671548e6cf7e#0"
    y = "d4c1747f2a6dea8f307f4846dab721798f141aeb156cb24221c5671548e6cf7e#1"
    z = "d4c1747f2a6dea8f307f4846dab721798f141aeb156cb24221c5671548e6cf7e#2"

    # Get the ordered list of strings
    ordered_list = sort_lexicographically(x, y, z)

    # Get and print the index of each string
    index_x = get_index_in_order(ordered_list, x)
    index_y = get_index_in_order(ordered_list, y)
    index_z = get_index_in_order(ordered_list, z)
    assert index_x == 0
    assert index_y == 1
    assert index_z == 2
