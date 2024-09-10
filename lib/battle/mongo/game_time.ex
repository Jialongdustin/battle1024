defmodule Battle.Mongo.GameTime do
  use Ejoy.Db

  @db "battle"
  @collection "game_time"
  @cleanable false
  @indexes [
    {[day_time: 1], false}
  ]

  field :begin_time, :string, required: true
  field :end_time, :string, required: false
  field :game_time, :string, required: false
  field :day_time, :string, required: false
  field :users, :integer, required: false

  def start_record() do
    info = %{
      begin_time: DateTime.utc_now() |> DateTime.to_string(),
      day_time: DateTime.utc_now() |> DateTime.to_date() |> Date.to_string()
    }
    __MODULE__.psave(info)
  end

  def end_record(games) do
    today = Date.utc_today() |> Date.to_string()
    case __MODULE__.pquery(%{day_time: today}) do
      [] ->
        yesterday = Date.utc_today() |> Date.add(today, -1) |> Date.to_string()
        info = __MODULE__.pquery(%{day_time: yesterday}) |> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()
        {:ok, begin_time, _} = DateTime.from_iso8601(info.begin_time)
        end_time = DateTime.utc_now()
        game_time = DateTime.diff(begin_time, end_time)
        bson_id = info._id
        __MODULE__.pupdate(%{_id: bson_id}, %{info | end_time: end_time |> DateTime.to_string(), game_time: "#{game_time}s", users: games})
      res ->
        info = res |> Enum.map(fn message -> message |> __MODULE__.to_raw() end) |> List.first()
        {:ok, begin_time, _} = DateTime.from_iso8601(info.begin_time)
        end_time = DateTime.utc_now()
        game_time = DateTime.diff(end_time, begin_time)
        bson_id = info._id
        __MODULE__.pupdate(%{_id: bson_id}, %{info | end_time: end_time |> DateTime.to_string(), game_time: "#{game_time}s", users: games})
    end
  end
end
