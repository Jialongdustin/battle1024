defmodule Battle.Mongo.BattleResult do
  use Ejoy.Db
  require Logger

  @db "battle"
  @collection "battle_result"
  @indexes [
    {[user_id_2: 1], false}
  ]
  @cleanable false

  field :user_id_2, {:list, :integer}, require: true
  field :contest_id, :integer, required: true
  field :winner, :integer, required: true
  field :time_cost_2, {:list, :integer}, required: true
  field :memory_cost_2, {:list,:string}, required: true
  field :early_hand, :integer, required: true
  field :total_step_2, {:list, :integer}, required: true

#  Battle.BattleResult.save_battle_result([1,2],1,1,[11,22],["11","22"],1,[20,30])


  def save_battle_result(users,contest_id,winner,time_costs,memory_costs,early_hand,total_steps) do
    info = %{
      user_id_2: users,
      contest_id: contest_id,
      winner: winner,
      time_cost_2: time_costs,
      memory_cost_2: memory_costs,
      early_hand: early_hand,
      total_step_2: total_steps
    }
    __MODULE__.psave(info)
  end

  def get_battle_result_by_user_id(user_id) do
    case pquery2(%{user_id_2: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id_2: 1]]}) do
      nil -> {:error,"Battle.BattleResult error "}
      res -> battle_info = res |> Enum.map(&__MODULE__.to_raw/1)
             self_and_opponent = Enum.map(battle_info, fn battle ->
               self_id = user_id
               user_ids = battle.user_id_2

               case Enum.find_index(user_ids, fn id -> id == self_id end) do
                 nil ->
                   # 如果找不到 self_id, 返回错误
                   {:error, "Self user id not found"}
                 self_index ->
                   opponent_index = if self_index == 0, do: 1, else: 0

                   self = %{
                     user_id_self: self_id,
                     time_cost_self: Enum.at(battle.time_cost_2, self_index),
                     total_step_self: Enum.at(battle.total_step_2, self_index),
                     memory_cost_self: Enum.at(battle.memory_cost_2, self_index),
                     contest_id: battle.contest_id,
                     early_hand: battle.early_hand,
                     winner: battle.winner
                   }

                   opponent_id = Enum.at(user_ids, opponent_index)

                   opponent = %{
                     user_id_opponent: opponent_id,
                     time_cost_opponent: Enum.at(battle.time_cost_2, opponent_index),
                     total_step_opponent: Enum.at(battle.total_step_2, opponent_index),
                     memory_cost_opponent: Enum.at(battle.memory_cost_2, opponent_index),
                     contest_id: battle.contest_id,
                     early_hand: battle.early_hand,
                     winner: battle.winner
                   }

                   {self, opponent}
               end
             end)

             {:ok, self_and_opponent}
    end
  end
end
