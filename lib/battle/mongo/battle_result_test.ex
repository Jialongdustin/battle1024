defmodule Battle.Mongo.BattleResultTest do

  use Ejoy.Db

  alias Battle.Mongo.UserAi
  alias Battle.Mongo.BattleStatistics

  @db "battle"
  @collection "battle_result_test"
  @indexes [
    {[user_id: 1], false},
    {[game_id: 1], false}
  ]
  @cleanable false

  field :user_id, :string, required: true
  field :game_id, :string, required: true
  field :date, :datetime, required: true
  field :ai_name, :string, required: true
  field :git_url, :string, required: true
  field :tag, :string, required: true
  field :winner, :integer, required: false
  field :time_cost_2, {:list, :integer}, required: false
  field :memory_cost_2, {:list,:string}, required: false
  field :early_hand, :integer, required: false
  field :total_step_2, {:list, :integer}, required: false

  def save_battle_result(user_id, game_id, ai_name, git_url, tag) do
    info = %{
      user_id: user_id,
      game_id: game_id,
      ai_name: ai_name,
      git_url: git_url,
      tag: tag,
      date: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def update_battle_result(game_id, winner, time_costs, memory_costs, total_steps) do
    {:ok, info} =  __MODULE__.pquery2(%{game_id: game_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[game_id: 1]]})
      |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
      |> List.first()
    bson_id = info._id
    if winner != nil do
      user_id = info.user_id
      git_url = info.gir_url
      tag = info.tag
      BattleStatistics.submit_increment()
      UserAi.update_git(user_id, git_url, tag)
    end
    __MODULE__.pupdate(%{_id: bson_id}, %{info | winner: winner, time_costs_2: time_costs, memory_costs_2: memory_costs, total_steps_2: total_steps})
  end

  def get_result_by_user_id(user_id) do
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [date: -1], 1) do
      nil -> {:error, "battletest_result not found"}
      res -> battle_info = res |> Enum.map(fn message -> message |> __MODULE__.to_raw() end)
            self_and_opponent = Enum.map(battle_info, fn battle ->
              white = %{
                time_cost_white: Enum.at(battle.time_cost_2, 0),
                total_step_white: Enum.at(battle.total_step_2, 0),
                memory_cost_white: Enum.at(battle.memory_cost_2, 0),
                game_id: battle.game_id,
                winner: battle.winner
              }
              black = %{
                time_cost_black: Enum.at(battle.time_cost_2, 1),
                total_step_black: Enum.at(battle.total_step_2, 1),
                memory_cost_black: Enum.at(battle.memory_cost_2, 1),
                game_id: battle.game_id,
                winner: battle.winner
              }
              %{white: white, black: black}
            end)
            {:ok, self_and_opponent}
    end
  end

  def get_battle_results() do
    case pquery(%{}) do
      nil -> {:error,"empty battle"}
      res ->
        {:ok,res |> Enum.map(&__MODULE__.to_raw/1) |> Enum.map(fn message ->  [message.user_id_2,message.winner] end)}
    end
  end

  def get_battle_results_within_24_hour() do
    time_query = Battle.Utils.GetTime24.get_time()
    case __MODULE__.pquery(time_query) do
      nil -> {:error, "empty rank list" }
      res ->{:ok, res |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)}
    end
  end

  def count_battle() do
    {:ok, count} = __MODULE__.pcount(%{})
    count
  end
end
