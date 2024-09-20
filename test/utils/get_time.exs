defmodule UtilsTest.GetTimeTest do
  use ExUnit.Case
  doctest Battle.Utils.GetTime24

  require Logger

  alias Battle.Utils.GetTime24
  alias Battle.Mongo.BattleStatistics

  test "get now" do
    date = DateTime.utc_now()
    # 根据当前日期生成开始和结束时间的字符串
    start_time_string = "#{Date.to_string(date)} 00:00:00"
    end_time_string = "#{Date.to_string(date)} 23:59:59"

    # 将字符串转换为 NaiveDateTime 类型
    {:ok, naive_start_time} = NaiveDateTime.from_iso8601("#{start_time_string}")
    {:ok, naive_end_time} = NaiveDateTime.from_iso8601("#{end_time_string}")

    # 将 NaiveDateTime 转为 UTC 日期时间
    {:ok, utc_start_time} = DateTime.from_naive(naive_start_time, "Etc/UTC")
    {:ok, utc_end_time} = DateTime.from_naive(naive_end_time, "Etc/UTC")

    # 将 UTC 时间转换为上海时区的时间
    {:ok, shanghai_start_time} = DateTime.shift_zone(utc_start_time, "Asia/Shanghai")
    {:ok, shanghai_end_time} = DateTime.shift_zone(utc_end_time, "Asia/Shanghai")

    # 打印结果
    IO.inspect(shanghai_start_time)
    IO.inspect(shanghai_end_time)
  end
end