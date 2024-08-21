defmodule Battle.Utils.GetTime24 do
  def get_time() do
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
  end
end
