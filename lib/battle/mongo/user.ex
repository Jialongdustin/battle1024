defmodule Battle.Mongo.User do
  use Ejoy.Db

  alias Battle.Mongo.UserAi
  @db "battle"
  @collection "user"
  @indexes [
    {[user_id: 1], true},
    {[account: 1], true}
  ]
  @cleanable false

  field :account, :string, required: true
  field :user_name, :string, required: false
  field :user_id, :string, required: true
  field :date, :datetime, required: true
  field :avatar, :string, required: false

  def save_user(user_id, account, user_name) do
     info = %{
     user_id: user_id,
     user_name: user_name,
     account: account,
     date: Ejoy.Bson.utc_now()
     }
     __MODULE__.psave(info)
   end


  def query_user(account) do
    case __MODULE__.pquery2(%{account: account},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[account: 1]]}) do
      [] -> {:error, "user_id error"}
      res -> {:ok, res |> Enum.map(fn message -> message|> __MODULE__.to_raw() end) |> List.first()}
    end
  end

  def update_avatar(user_id, avatar) do
    info = __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]})
        |>  Enum.map(fn message -> message|> __MODULE__.to_raw() end)
        |> List.first()
    __MODULE__.pupdate(%{user_id: user_id}, %{info | avatar: avatar})
  end

  def remove_user(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end

  def get_user_name(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "user_id error"}
      res -> user_info = res|>Enum.map(fn message -> message|> __MODULE__.to_raw() end) |> List.first()

        {:ok, user_info.user_name}
    end
  end
end
