defmodule Battle.Mongo.User do
  use Ejoy.Db

  alias Battle.Mongo.UserAi
  @db "battle"
  @collection "rank_list"
  @indexes [
    {[user_id: 1], true}
  ]
  @cleanable false

  field :account, :integer, required: true
  field :user_id, :integer, required: true
  field :date, :datetime, required: true
  field :avatar, :string, required: false

  def save_user(user_id,account) do
    info = %{
    user_id: user_id,
    account: account,
    date: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def query_user(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "user_id error"}
      res -> {:ok,res|>Enum.map(fn message -> message|> __MODULE__.to_raw() end)|>List.first()}
    end
  end

  def update_avatar(user_id,avatar) do
    {:ok, info} = query_user(user_id)
    __MODULE__.pupdate(%{user_id: user_id},%{info | avatar: avatar})
  end
end
