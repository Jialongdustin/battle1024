defmodule Battle.RankList do
  use Ejoy.Db
  require Logger

  @db "battle"
  @collection "rank_list"
  @indexes [
    {[user_id: 1], false}
  ]
  @cleanable false

  field :user_id, :integer, required: true
  field :ai_name, :string, required: true
  field :rate, :float, required: true
  field :date, :datetime, required: true

  def get_rank_list() do
    date = DateTime.utc_now()

    # 根据当前日期生成开始和结束时间的字符串
    start_time_string = "#{Date.to_string(date)} 00:00:00"
    end_time_string = "#{Date.to_string(date)} 23:59:59"

    # 将字符串转换为 DateTime 类型
    {:ok, start_time,_offset} = DateTime.from_iso8601("#{start_time_string}Z")
    {:ok, end_time,_offset} = DateTime.from_iso8601("#{end_time_string}Z")

#    mill = :erlang.system_time()

    # 将 DateTime 转换为 Unix 时间戳（以毫秒为单位）
    start = DateTime.to_unix(start_time, :millisecond)
    last = DateTime.to_unix(end_time, :millisecond)

#    Battle.RankList.get_rank_list()

    time_query = %{
      date: %{
        "$gte": %Bson.UTC{ ms: start},
        "$lte": %Bson.UTC{ ms: last}
      }
    }
    Logger.info(time_query)
    case __MODULE__.pquery(time_query) do
      nil -> {:error, "empty rank list" }
      res ->res |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
    end
  end

  def get_rank_by_user_id(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      nil ->{:error, "user_id error"}
      res ->{:ok, res|>__MODULE__.to_raw()}
    end
  end

  def save_rank(user_id, ai_name, rate) do
    current_time = Ejoy.Bson.utc_now()
    __MODULE__.psave(%{user_id: user_id, ai_name: ai_name, rate: rate, date: current_time})
    #UserAi.insert_ai(1,"Biu","git.com","1.0")
    #UserAi.get_ai_list_by_userId(1)
  end
end
