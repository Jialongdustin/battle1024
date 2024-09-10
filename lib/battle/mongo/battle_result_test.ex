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
  field :winner, :string, required: false
  field :time_cost_2, {:list, :integer}, required: false
  field :memory_cost_2, {:list, :string}, required: false
  field :early_hand, :string, required: false
  field :total_step_2, {:list, :integer}, required: false
  field :code, :integer, required: true

  def save_battle_result(user_id, game_id, ai_name, git_url, tag) do
    info = %{
      user_id: user_id,
      game_id: game_id,
      ai_name: ai_name,
      git_url: git_url,
      tag: tag,
      code: 2001,
      date: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def update_battle_result_failed(game_id, reason) do
    info =  __MODULE__.pquery2(%{game_id: game_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[game_id: 1]]})
      |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
      |> List.first()

    bson_id = info._id
    __MODULE__.pupdate(%{_id: bson_id}, %{info | code: if(reason == "git or tag illegal", do: 2002, else: 2003)})
  end

  def update_battle_result(game_id, early_hand, winner, time_costs, memory_costs, total_steps, code \\ 2001) do
    info =  __MODULE__.pquery2(%{game_id: game_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[game_id: 1]]})
      |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
      |> List.first()

    bson_id = info._id
    code = if winner, do: 2000, else: code
    if winner != nil do
      user_id = info.user_id
      git_url = info.git_url
      tag = info.tag
      {:ok, user_info} = UserAi.get_newest_ai_by_userId(user_id)
      if user_info.git_url == nil do
        BattleStatistics.user_increment()
      end
      BattleStatistics.submit_increment()
      BattleStatistics.update_last_commit_time(Ejoy.Bson.utc_now())
      UserAi.update_git(user_id, git_url, tag)
    end
    __MODULE__.pupdate(%{_id: bson_id}, %{info | winner: winner, time_cost_2: time_costs, memory_cost_2: memory_costs, early_hand: early_hand, total_step_2: total_steps, code: code})
  end

  # BattleResultTest.get_result_by_user_id("111")
  def get_result_by_user_id(user_id) do
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [date: -1], 1) do
      [] -> {:error, "battletest_result not found"}
      res -> battle_info = res |> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()
            {:ok, battle_info.code}
    end
  end

  def get_all_results_by_user_id(user_id) do
    case __MODULE__.pquery_sort(%{user_id: user_id}, [date: -1]) do
      [] -> {:error, "no results of test game"}
      res -> battle_info = res |> Enum.map(fn message -> message |> __MODULE__.to_raw() end)
              self_and_opponent = Enum.map(battle_info, fn battle ->
                if battle.early_hand do
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
                    %{white: white, black: black, tag: battle.tag}
               end
            end) |> Enum.filter(& &1)
            {:ok, self_and_opponent}
    end
  end


  def get_battle_results_within_24_hour() do
    time_query = Battle.Utils.GetTime24.get_time()
    case __MODULE__.pquery(time_query) do
      [] -> {:error, "empty rank list" }
      res ->{:ok, res |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)}
    end
  end


  def get_newest_time_by_user_id(user_id) do
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [date: -1], 1) do
      [] -> {:error, "not submit"}
      res -> detail = res |> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()
             {:ok, detail.date.ms}
    end
  end

  # BattleResultTest.get_battle_results()
  def remove_all_battle(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end

  def count_submit(user_id) do
    info = %{user_id: user_id, code: 2000}
    __MODULE__.pcount(info)
  end

end
