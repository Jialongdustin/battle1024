defmodule UtilsTest.ConvertTest do
  use ExUnit.Case
  doctest Battle.Utils.Convert

  require Logger

  alias Battle.Utils.Convert
  alias Battle.Mongo.BattleStatistics

  test "convert_s_to_i" do
    moves = [["a", "1"], ["c", "1"]]
    assert Convert.convert_index_into_integer(moves) == [[7, 0], [7, 2]]
  end

  test "convert_i_to_s" do
    moves = [[0, 3], [5, 3]]
    assert Convert.convert_integer_into_string(moves) == [["d", "8"], ["d", "3"]]
  end

  test "convert board" do
    board = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [3, 3, 3, 3, 3, 3, 3, 3],
      [3, 3, 3, 3, 3, 3, 3, 3],
      [0, 0, 0, 0, 0, 0, 0, 0]
    ]

    res = Convert.convert_array_list(board)

    expect = [
      %{index: ["a", "8"], value: 0},
      %{index: ["b", "8"], value: 0},
      %{index: ["c", "8"], value: 0},
      %{index: ["d", "8"], value: 0},
      %{index: ["e", "8"], value: 0},
      %{index: ["f", "8"], value: 0},
      %{index: ["g", "8"], value: 0},
      %{index: ["h", "8"], value: 0},
      %{index: ["a", "7"], value: 1},
      %{index: ["b", "7"], value: 1},
      %{index: ["c", "7"], value: 1},
      %{index: ["d", "7"], value: 1},
      %{index: ["e", "7"], value: 1},
      %{index: ["f", "7"], value: 1},
      %{index: ["g", "7"], value: 1},
      %{index: ["h", "7"], value: 1},
      %{index: ["a", "6"], value: 1},
      %{index: ["b", "6"], value: 1},
      %{index: ["c", "6"], value: 1},
      %{index: ["d", "6"], value: 1},
      %{index: ["e", "6"], value: 1},
      %{index: ["f", "6"], value: 1},
      %{index: ["g", "6"], value: 1},
      %{index: ["h", "6"], value: 1},
      %{index: ["a", "5"], value: 0},
      %{index: ["b", "5"], value: 0},
      %{index: ["c", "5"], value: 0},
      %{index: ["d", "5"], value: 0},
      %{index: ["e", "5"], value: 0},
      %{index: ["f", "5"], value: 0},
      %{index: ["g", "5"], value: 0},
      %{index: ["h", "5"], value: 0},
      %{index: ["a", "4"], value: 0},
      %{index: ["b", "4"], value: 0},
      %{index: ["c", "4"], value: 0},
      %{index: ["d", "4"], value: 0},
      %{index: ["e", "4"], value: 0},
      %{index: ["f", "4"], value: 0},
      %{index: ["g", "4"], value: 0},
      %{index: ["h", "4"], value: 0},
      %{index: ["a", "3"], value: 3},
      %{index: ["b", "3"], value: 3},
      %{index: ["c", "3"], value: 3},
      %{index: ["d", "3"], value: 3},
      %{index: ["e", "3"], value: 3},
      %{index: ["f", "3"], value: 3},
      %{index: ["g", "3"], value: 3},
      %{index: ["h", "3"], value: 3},
      %{index: ["a", "2"], value: 3},
      %{index: ["b", "2"], value: 3},
      %{index: ["c", "2"], value: 3},
      %{index: ["d", "2"], value: 3},
      %{index: ["e", "2"], value: 3},
      %{index: ["f", "2"], value: 3},
      %{index: ["g", "2"], value: 3},
      %{index: ["h", "2"], value: 3},
      %{index: ["a", "1"], value: 0},
      %{index: ["b", "1"], value: 0},
      %{index: ["c", "1"], value: 0},
      %{index: ["d", "1"], value: 0},
      %{index: ["e", "1"], value: 0},
      %{index: ["f", "1"], value: 0},
      %{index: ["g", "1"], value: 0},
      %{index: ["h", "1"], value: 0}
    ]
    assert expect == res
  end
end
