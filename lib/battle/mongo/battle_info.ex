defmodule Battle.Mongo.BattleInfo do
  use Ejoy.Db

  require Logger

  @db "battle"
  @collection "battle_info"
  @indexes [
    {[game_id: 1], false}
  ]
  @cleanable false

  field :game_id, :string, required: true
  field :steps, :integer, required: true
  field :detail, {:list, :map}, required: true
#  field :date, :datetime, required: true

  def insert_battle(game_id, steps, detail) do
    info = %{game_id: game_id, steps: steps, detail: detail}
    __MODULE__.psave(info)
  end

  def get_battle_by_game_id(game_id) do
    case __MODULE__.pquery2(%{game_id: game_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[game_id: 1]]}) do
      nil -> {:error, "game not exist"}
      res -> {:ok, res |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)}
    end
  end

  def remove_battle(game_id) do
    __MODULE__.pdelete(%{game_id: game_id}, false)
  end
end
