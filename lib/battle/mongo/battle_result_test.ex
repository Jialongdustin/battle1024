defmodule Battle.Mongo.BattleResultTest do

  use Ejoy.Db

  @db "battle"
  @collection "user_ai"
  @indexes [
    {[user_id: 1], false}
  ]
  @cleanable false

  field :user_id, :integer, required: true
  field :ai_name, :string, required: true
  field :tag, :string, required: true
  field :winner, :integer, required: true
  field :time_cost_2, {:list, :integer}, required: true
  field :memory_cost_2, {:list,:string}, required: true
  field :early_hand, :integer, required: true
  field :total_step_2, {:list, :integer}, required: true


end
