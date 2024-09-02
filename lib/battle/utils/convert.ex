defmodule Battle.Utils.Convert do
  @moduledoc false

  @reflection_s_to_i %{
    "8" => 0,
    "7" => 1,
    "6" => 2,
    "5" => 3,
    "4" => 4,
    "3" => 5,
    "2" => 6,
    "1" => 7,
    "a" => 0,
    "b" => 1,
    "c" => 2,
    "d" => 3,
    "e" => 4,
    "f" => 5,
    "g" => 6,
    "h" => 7
  }

  @reflection_y_to_x %{
    0 => "a",
    1 => "b",
    2 => "c",
    3 => "d",
    4 => "e",
    5 => "f",
    6 => "g",
    7 => "h"
  }
  @reflection_x_to_y %{
    0 => "8",
    1 => "7",
    2 => "6",
    3 => "5",
    4 => "4",
    5 => "3",
    6 => "2",
    7 => "1"
  }

  def convert_index_into_integer(moves) do
    Enum.map(moves, fn [x, y] -> [@reflection_s_to_i[y], @reflection_s_to_i[x]] end)
  end

  def convert_integer_into_string(moves) do
    Enum.map(moves, fn [x, y] -> [@reflection_y_to_x[y], @reflection_x_to_y[x]] end)
  end

  def convert_array_list(board) do

    Enum.reduce(0..(length(board) - 1), [], fn x, acc ->
      Enum.reduce(0..(length(Enum.at(board, 0)) - 1), acc, fn y, acc_inner ->
        value = Enum.at(board, x) |> Enum.at(y)
        [%{index: [@reflection_y_to_x[y], @reflection_x_to_y[x]], value: value} | acc_inner]
      end)
    end)
    |> Enum.reverse() # 保持原始顺序
  end

end
