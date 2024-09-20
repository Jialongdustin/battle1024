defmodule Battle.Mongo.BattleResult do
  use Ejoy.Db
  require Logger

  alias Battle.Mongo.UserAi

  @db "battle"
  @collection "battle_result"
  @indexes [
    {[user_id_2: 1], false}
  ]
  @cleanable false

  field :user_id_2, {:list, :string}, require: true
  field :game_id, :string, required: true
  field :winner, :string, required: true
  field :time_cost_2, {:list, :integer}, required: true
  field :memory_cost_2, {:list,:string}, required: true
  field :early_hand, :string, required: true
  field :total_step_2, {:list, :integer}, required: true
  field :date, :datetime, required: true


  #  Battle.Mongo.BattleResult.save_battle_result([1,2],1,1,[11,22],["11","22"],1,[20,30])

  def save_battle_result(users, game_id, winner, time_costs, memory_costs, early_hand, total_steps) do
    info = %{
      user_id_2: users,
      game_id: game_id,
      winner: winner,
      time_cost_2: time_costs,
      memory_cost_2: memory_costs,
      early_hand: early_hand,
      total_step_2: total_steps,
      date: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def get_battle_result_by_user_id(user_id) do
    case __MODULE__.pquery_sort(%{user_id_2: user_id}, [date: -1]) do
      [] -> {:error, "no games of user"}
      res -> battle_info = res |> Enum.map(&__MODULE__.to_raw/1)
             self_and_opponent = Enum.map(battle_info, fn battle ->
               self_id = user_id
               {:ok, self_ai_name} = UserAi.get_ai_name(self_id)
               user_ids = battle.user_id_2
               case Enum.find_index(user_ids, fn id -> id == self_id end) do
                 nil ->
                   # 如果找不到 self_id, 返回错误
                   {:error, "Self user id not found"}
                 self_index ->
                   opponent_index = if self_index == 0, do: 1, else: 0
                   {:ok,early_hand_name} = UserAi.get_ai_name(battle.early_hand)
                   self = %{
                     user_id_self: self_id,
                     ai_name_self: self_ai_name,
                     time_cost_self: Enum.at(battle.time_cost_2, self_index),
                     total_step_self: Enum.at(battle.total_step_2, self_index),
                     memory_cost_self: Enum.at(battle.memory_cost_2, self_index),
                     game_id: battle.game_id,
                     early_hand: early_hand_name,
                     winner: battle.winner,
                     date: battle.date.ms
                   }

                   opponent_id = Enum.at(user_ids, opponent_index)
                   {:ok, opponent_ai_name} = UserAi.get_ai_name(opponent_id)
                   opponent = %{
                     user_id_opponent: opponent_id,
                     ai_name_opponent: opponent_ai_name,
                     time_cost_opponent: Enum.at(battle.time_cost_2, opponent_index),
                     total_step_opponent: Enum.at(battle.total_step_2, opponent_index),
                     memory_cost_opponent: Enum.at(battle.memory_cost_2, opponent_index),
                     game_id: battle.game_id,
                     early_hand: early_hand_name,
                     winner: battle.winner,
                     date: battle.date.ms
                   }

                   %{self: self, opponent: opponent}
               end
             end)
             {:ok, self_and_opponent}
    end
  end

  def get_battle_results() do
    case pquery(%{}) do
      [] -> {:error, "empty battle"}
      res ->
        {:ok, res |> Enum.map(&__MODULE__.to_raw/1)|>Enum.map(fn message ->  [message.user_id_2,message.winner] end)}
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

  def count_battle() do
    {:ok, count} = __MODULE__.pcount(%{})
    count
  end

  def remove_battle(user_id) do
    __MODULE__.pdelete(%{user_id_2: user_id}, false)
  end
end
