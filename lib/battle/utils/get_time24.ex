defmodule Battle.Utils.GetTime24 do
  def get_time() do
    date = DateTime.utc_now()
    # 提取当前小时数
    current_hour = date.hour
    IO.inspect(current_hour)
    # 判断当前时间的小时数
    {start_time_string, end_time_string} =
      if current_hour >= 16 do
        # 设置 start_time_string 为今天的 16:00:00，end_time_string 为明天的 16:00:00

        {
          "#{Date.to_string(date)} 16:00:00",
          "#{Date.to_string(date|> Date.add(1))} 16:00:00"
        }
      else

        # 设置 start_time_string 为昨天的 16:00:00，end_time_string 为今天的 16:00:00
        {
          "#{Date.to_string(date|> Date.add(-1))} 16:00:00",
        "#{Date.to_string(date)} 16:00:00"
        }
      end
    # 将字符串转换为 DateTime 类型
    {:ok, start_time, _offset} = DateTime.from_iso8601("#{start_time_string}Z")
    {:ok, end_time, _offset} = DateTime.from_iso8601("#{end_time_string}Z")

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

  def get_yesterday_time() do
    # 获取当前 UTC 时间并减去 1 天
    date = DateTime.utc_now() |> DateTime.add(-86400, :second)
    current_hour = date.hour
    {start_time_string, end_time_string} =
      if current_hour >= 16 do
        # 设置 start_time_string 为今天的 16:00:00，end_time_string 为明天的 16:00:00

        {
          "#{Date.to_string(date)} 16:00:00",
          "#{Date.to_string(date|> Date.add(1))} 16:00:00"
        }
      else

        # 设置 start_time_string 为昨天的 16:00:00，end_time_string 为今天的 16:00:00
        {
          "#{Date.to_string(date|> Date.add(-1))} 16:00:00",
          "#{Date.to_string(date)} 16:00:00"
        }
      end

    # 将字符串转换为 DateTime 类型
    {:ok, start_time, _offset} = DateTime.from_iso8601("#{start_time_string}Z")
    {:ok, end_time, _offset} = DateTime.from_iso8601("#{end_time_string}Z")

    # 将 DateTime 转换为 Unix 时间戳（以毫秒为单位）
    start = DateTime.to_unix(start_time, :millisecond)
    last = DateTime.to_unix(end_time, :millisecond)

    # 构造用于 MongoDB 查询的时间查询语句
    time_query = %{
      date: %{
        "$gte": %Bson.UTC{ ms: start},
        "$lte": %Bson.UTC{ ms: last}
      }
    }

    # 返回时间查询
    time_query
  end

  def get_48h_before() do
    # 获取当前 UTC 时间并减去 2 天
    date = DateTime.utc_now() |> DateTime.add(-(86400*2), :second)
    start_time_string = "#{Date.to_string(date|> Date.add(-1))} 16:00:00"
    end_time_string = "#{Date.to_string(date)} 16:00:00"

    # 将字符串转换为 DateTime 类型
    {:ok, start_time, _offset} = DateTime.from_iso8601("#{start_time_string}Z")
    {:ok, end_time, _offset} = DateTime.from_iso8601("#{end_time_string}Z")

    # 将 DateTime 转换为 Unix 时间戳（以毫秒为单位）
    start = DateTime.to_unix(start_time, :millisecond)
    last = DateTime.to_unix(end_time, :millisecond)

    # 构造用于 MongoDB 查询的时间查询语句
    time_query = %{
      date: %{
        "$gte": %Bson.UTC{ ms: start},
        "$lte": %Bson.UTC{ ms: last}
      }
    }

    # 返回时间查询
    time_query
  end

  def get_24h_before_any_date(time) do
    # 转换毫秒级时间戳为秒级时间戳
    timestamp_in_sec = div(time, 1000)

    # 将秒级时间戳转换为 DateTime
    {:ok, datetime} = DateTime.from_unix(timestamp_in_sec)

    # 获取日期部分
    date = datetime |> DateTime.to_date()

    # 生成昨天 16:00:00 和今天 16:00:00 的字符串
    start_time_string = "#{Date.to_string(Date.add(date, -2))} 16:00:00"
    end_time_string = "#{Date.to_string(Date.add(date, -1))} 16:00:00"

    # 将字符串转换为 DateTime 类型
    {:ok, start_time, _offset} = DateTime.from_iso8601("#{start_time_string}Z")
    {:ok, end_time, _offset} = DateTime.from_iso8601("#{end_time_string}Z")

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
