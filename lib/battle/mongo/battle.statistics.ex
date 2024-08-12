defmodule Battle.BattleStatistics do
  use Ejoy.Db
  require Logger

  @db "battle"
  @collection "battle_statistics"
#  @indexes [
#    {[contest_id: 1], false}
#  ]
  @cleanable false

  field :user_count, :integer, required: true
  field :submit_count, :integer, required: true
  field :average_step, :integer, required: true

  def query_statistics_info() do
    case __MODULE__.pquery(%{}) do
      nil -> {:error,"no info in battle_statistics"}
      res -> {:ok, res|> Enum.map( fn message -> message |> __MODULE__.to_raw() end)|>List.first()}
    end
  end

  def save_statistics_info(user_count, submit_count, average_step) do
    info = %{user_count: user_count, submit_count: submit_count, average_step: average_step}
    __MODULE__.psave(info)
  end

  def increase_submit() do
    {:ok,info} = query_statistics_info
    bson_id = info._id
    count = info.submit_count+1
    __MODULE__.pupdate(%{_id: bson_id}, %{info | submit_count: count})
  end
end
