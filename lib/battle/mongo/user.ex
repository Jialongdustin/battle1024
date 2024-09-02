defmodule Battle.Mongo.User do
  use Ejoy.Db

  alias Battle.Mongo.UserAi
  @db "battle"
  @collection "user"
  @indexes [
    {[user_id: 1], true}
  ]
  @cleanable false

  field :account, :string, required: true
  field :user_name, :string, required: false
  field :user_id, :string, required: true
  field :date, :datetime, required: true
  field :avatar, :string, required: false

  # @default_avatar <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72, 0, 72,
  #                   0, 0, 255, 225, 0, 142, 69, 120, 105, 102, 0, 0, 77, 77, 0, 42, 0, 0, 0, 8,
  #                   0, 5, 1, 18, 0, 3, 0, 0, 0, ...>>

  # def save_user(user_id, account, user_name) do
  #   info = %{
  #   user_id: user_id,
  #   user_name: user_name,
  #   account: account,
  #   date: Ejoy.Bson.utc_now()
  #   }
  #   __MODULE__.psave(info)
  # end

  def save_user(user_id, account) do
    case query_user(user_id) do
      {:ok, info} ->
        __MODULE__.pupdate(%{user_id: user_id}, %{info | date: Ejoy.Bson.utc_now()})
      {:error, _} ->
        info =  %{
          user_id: user_id,
          account: account,
          # avatar: @default_avatar,
          date: Ejoy.Bson.utc_now()
        }
        __MODULE__.psave(info)
    end
  end

  def query_user(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "user_id error"}
      res -> {:ok, res |> Enum.map(fn message -> message|> __MODULE__.to_raw() end) |> List.first()}
    end
  end

  def update_avatar(user_id, avatar) do
    {:ok, info} = query_user(user_id)
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
