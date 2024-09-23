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
  field :package_name, :string, required: false

  def get_newest_ai_by_userId(user_id)do
    case __MODULE__.pquery2(%{user_id: user_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "Battle.UserAi error"}
      res -> {:ok, res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()}
    end
  end

  def get_all_gits() do
    mill = :erlang.system_time(:second)  # 获取当前时间的秒级时间戳
    time_24 = mill - rem(mill, 86400)  # 计算当天 00:00:00 的秒级时间戳

    # 查询条件，将 create_time 小于或等于 time_24 的记录取出
    time_query = %{create_time: %{"$lte": time_24}}

    case __MODULE__.pquery(time_query) do
      [] -> {:error, "no user_info"}
      res ->{:ok, res|> Enum.filter(fn message -> message.git_url != nil and message.tag != nil end)
                  |> Enum.map(fn message -> %{user_id: message.user_id, package_name: message.package_name} end)}
    end
  end

  def insert_ai(user_id, ai_name) do
    info = %{
      user_id: user_id,
      ai_name: ai_name,
      create_time: Ejoy.Bson.utc_now(),
      code: 100
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

  def update_git(user_id, url, tag, package_name) do
    {:ok, user_info} = get_newest_ai_by_userId(user_id)
    info = %{
      user_id: user_id,
      ai_name: user_info.ai_name,
      create_time: Ejoy.Bson.utc_now(),
      code: 100,
      url: url,
      tag: tag,
      package_name: package_name,
      create_time: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def clean_message(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end


end
