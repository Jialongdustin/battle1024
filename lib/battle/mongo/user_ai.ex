defmodule Battle.Mongo.UserAi do

  use Ejoy.Db

  @db "battle"
  @collection "user_ai"
  @indexes [
    {[user_id: 1], false}
  ]
  @cleanable false

  field :user_id, :string, required: true
  field :ai_name, :string, required: true
  field :git_url, :string, required: false
  field :tag, :string, required: false
  field :create_time, :datetime, required: false

  def get_newest_ai_by_userId(user_id)do
    case __MODULE__.pquery2(%{user_id: user_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "Battle.UserAi error"}
      res -> {:ok, res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()}
    end
  end

  def get_all_gits() do
    case __MODULE__.pquery(%{}) do
      [] -> {:error, "no user_info"}
      res ->{:ok, res|> Enum.filter(fn message -> message.git_url != nil and message.tag != nil end) |> Enum.map(fn message -> %{user_id: message.user_id, git_url: message.git_url, tag: message.tag} end)}
    end
  end

  def insert_ai(user_id, ai_name) do
    info = %{
      user_id: user_id,
      ai_name: ai_name,
      create_time: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def get_ai_name(user_id) do
    case __MODULE__.pquery(%{user_id: user_id}) do
      [] -> {:error, "no user_info"}
      res ->
        info = res |> Enum.map(fn message ->message |> __MODULE__.to_raw() end)|> List.first()
        {:ok, info.ai_name}
    end
  end

  def update_git(user_id, url, tag) do
      {:ok, user_info} = get_newest_ai_by_userId(user_id)
      bson_id = user_info._id
      __MODULE__.pupdate(%{_id: bson_id},%{user_info | git_url: url, tag: tag})
  end

  def clean_message(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end
end
