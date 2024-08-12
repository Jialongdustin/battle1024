defmodule Battle.Mongo.BattleInfo do

  use Ejoy.Db

  require Logger

  @db "battle"
  @collection "battle_info"
  @indexes [
    {[contest_id: 1], false}
  ]
  @cleanable false

  field :contest_id, :integer, required: true
  field :steps, :integer, required: true
  field :detail, :string, required: true
#  field :date, :datetime, required: true

  def insert_battle(contest_id, steps, detail) do
    info = %{contest_id: contest_id, steps: steps, detail: detail}
    __MODULE__.psave(info)
  end

  def get_battle_by_contest_id(contest_id) do
    case __MODULE__.pquery2(%{contest_id: contest_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[contest_id: 1]]}) do
      nil -> {:error, "contest not exist"}
      res -> {:ok, res |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)}
    end
  end
end
