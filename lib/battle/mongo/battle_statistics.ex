defmodule Battle.Mongo.BattleStatistics do

  use Ejoy.Db
  require Logger
  @db "battle"
  @collection "battle_statistics"
#  @indexes [
#    {[game_id: 1], false}
#  ]
  @cleanable false

  field :user_count, :integer, required: true
  field :submit_count, :integer, required: true
  field :average_step, :float, required: true
  field :average_time_cost, :float, required: true
  field :last_submit_time, :datetime, required: true

  def query_statistics_info() do
    case __MODULE__.pquery(%{}) do
      [] -> {:error, "no info in battle_statistics"}
      res -> {:ok, res|> Enum.map( fn message -> message |> __MODULE__.to_raw() end) |> List.first()}
    end
  end

  def update_statistics_info(user_count, submit_count, average_step,average_time_cost) do
    {:ok, info} = query_statistics_info()
    update_time = Battle.Mongo.UserAi.get_newest_submit_time()
    info = %{ info |
      user_count: user_count,
      submit_count: submit_count,
      average_step: average_step,
      average_time_cost: average_time_cost,
      last_submit_time: update_time
    }
    __MODULE__.pupdate(%{_id: info._id}, info)
  end

  # 这里初始化就往db插一条数据，方便后续拿数据计算，项目启动后只需要调用一次
  def save_init() do
    info = %{user_count: 0,
      submit_count: 0,
      average_step: 0,
      average_time_cost: 0,
      last_submit_time: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def user_increment() do
    {:ok, info} = query_statistics_info()
    bson_id = info._id
    count = info.submit_count+1
    __MODULE__.pupdate(%{_id: bson_id}, %{info | user_count: count})
  end

  def submit_increment() do
    {:ok, info} = query_statistics_info()
    bson_id = info._id
    count = info.submit_count+1
    __MODULE__.pupdate(%{_id: bson_id}, %{info | submit_count: count})
  end

  def update_average_step(steps) do
    battle_count = Battle.Mongo.BattleResult.count_battle()
    {:ok, info} = query_statistics_info()
    bson_id = info._id
    count = (info.average_step*battle_count+steps)/(battle_count+1)
    __MODULE__.pupdate(%{_id: bson_id}, %{info | average_step: count})
  end

  def update_average_time_cost(times) do
    {:ok, info} = query_statistics_info()
    battle_count = Battle.Mongo.BattleResult.count_battle()
    bson_id = info._id
    count = (info.average_time_cost*battle_count+times/1000)/(battle_count+1)
    __MODULE__.pupdate(%{_id: bson_id}, %{info | average_time_cost: count})
  end

  def update_last_commit_time(time) do
    {:ok, info} = query_statistics_info()
    bson_id = info._id
    __MODULE__.pupdate(%{_id: bson_id}, %{info | last_submit_time: time})
  end

  def delete_message() do
    __MODULE__.pdelete(%{}, false)
  end

end
