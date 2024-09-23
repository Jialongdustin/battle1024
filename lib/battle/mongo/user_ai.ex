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
    time_query = %{create_time: %{"$lte": %Bson.UTC{ ms: time_24*1000}}}
    IO.inspect(time_query)

    case __MODULE__.pquery(time_query) do
      [] ->
        {:error, "no user_info"}
      res ->
        info = res
        |> Enum.filter(fn message -> message.git_url != nil and message.tag != nil end)  # 过滤出 git_url 和 tag 不为空的记录
        |> Enum.group_by(& &1.user_id)  # 根据 user_id 进行分组
#        IO.inspect(info)
        |> Enum.map(fn {user_id, messages} ->
          # 对于每个 user_id 的记录，按 create_time 排序，取时间最近的一条
          latest_message = Enum.max_by(messages, & &1.create_time)
          %{
            user_id: latest_message.user_id,
            package_name: latest_message.package_name
          }
        end)
        |> fn filtered_messages -> {:ok, filtered_messages} end.()
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
      git_url: url,
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
