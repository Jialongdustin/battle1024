defmodule BattleTest.BattleHandlerTest do
  use ExUnit.Case
  import Mock
  #  doctest Battle.BattleDfs
  doctest Battle.BattleHandler
  alias Battle.BattleHandler

  @board [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 2, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ]
  @board2 [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 3, 0, 2, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ]


  test "get free list" do
    move_list = BattleHandler.get_free_list(@board,2,0,Enum.at(Enum.at(@board,2),0))
    assert [[[2, 0], [3, 0]], [[2, 0], [2, 1]]] == move_list
  end

  test "move list" do
    move_list = BattleHandler.move_list(@board,true)
    assert {
             [
               [[2, 0], [3, 0]],
               [[2, 0], [2, 1]],
               [[2, 2], [2, 1]],
               [[2, 2], [7, 2]],
               [[2, 2], [6, 2]],
               [[2, 2], [5, 2]],
               [[2, 2], [4, 2]],
               [[2, 2], [3, 2]],
               [[2, 2], [2, 7]],
               [[2, 2], [2, 6]],
               [[2, 2], [2, 5]],
               [[2, 2], [2, 4]],
               [[2, 2], [2, 3]],
               [[2, 2], [0, 2]],
               [[2, 2], [1, 2]]
             ],
             false
           }
           == move_list
  end

  test "move list black" do
    move_list = BattleHandler.move_list(@board,false)

    assert {[[[5, 0], [1, 0]], [[5, 0], [0, 0]]], true} == move_list
  end

  test "dfs normal" do
    move_list = BattleHandler.dfs(@board,2,0,"white",8,8)
    IO.inspect(move_list)
    assert  [[[2, 0]]] == move_list
  end

  test "dfs normal capture" do
    move_list = BattleHandler.dfs(@board2,2,0,"white",8,8)
    assert  [[[2, 0],[2,2]]] == move_list
  end

  test "dfs lady" do
    move_list = BattleHandler.dfs_lady(@board,5,0,"black",8,8,0,0)
    assert [[[5, 0], [0, 0]], [[5, 0], [1, 0]]] == move_list
  end

end