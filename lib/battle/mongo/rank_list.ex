defmodule Battle.Mongo.RankList.pensure_indexes() do
  use Ejoy.Db

  alias Battle.Mongo.UserAi
  alias Battle.Mongo.User
  alias Battle.Mongo.BattleResultTest

  @db "battle"
  @collection "rank_list"
  @indexes [
    {[rate: 1], false},
    {[user_id: 1], false},
    {[rate: 1,date: 1],false},
    {[date: 1],false}
  ]
  @cleanable false

  field :user_id, :string, required: true
  field :ai_name, :string, required: true
  field :rate, :float, required: true
  field :date, :datetime, required: true
  field :rank, :integer, required: false

  def get_rank_list(page, limit) do
    time_query = Battle.Utils.GetTime24.get_time()
    case __MODULE__.pquery_sort_limit(time_query, [rate: -1, date: -1], limit, page*limit) do
      [] ->
        time_query_yesterday = Battle.Utils.GetTime24.get_yesterday_time()
        case __MODULE__.pquery_sort_limit(time_query_yesterday, [rate: -1], limit, page*limit) do
          [] -> {:error,"no match"}
          res ->
            details = res |> Enum.map(fn message ->
              message = message |> __MODULE__.to_raw()
              {:ok, user_info} = User.query_user(message.user_id)
              time_query_48h_before = Battle.Utils.GetTime24.get_48h_before()
              rank_48h_before =
                case __MODULE__.pquery2(%{user_id: message.user_id,date: time_query_48h_before.date},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
                  [] -> []
                  res -> res
                         |> Enum.map(fn message ->
                    message
                    |> __MODULE__.to_raw()
                  end)
                         |> List.first()
                end
              %{
                ai_name: message.ai_name,
                user_id: message.user_id,
                rate: message.rate,
                avatar: user_info.avatar,
                rank: message.rank,
                rank_abs: (if rank_48h_before == [], do: nil, else: rank_48h_before.rank - message.rank),

              }
            end)
            {:ok, details}
        end
      res ->
        details = res |> Enum.map(fn message ->
          message = message |> __MODULE__.to_raw()
          {:ok, user_info} = User.query_user(message.user_id)
          time_query_yesterday = Battle.Utils.GetTime24.get_yesterday_time()
          rank_yesterday =
            case __MODULE__.pquery2(%{user_id: message.user_id,date: time_query_yesterday.date},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
              [] -> []
              res -> res
                     |> Enum.map(fn message ->
                message
                |> __MODULE__.to_raw()
              end)
                     |> List.first()
            end
          IO.inspect(rank_yesterday)
          %{
            ai_name: message.ai_name,
            user_id: message.user_id,
            rate: message.rate,
            avatar: user_info.avatar,
            rank: message.rank,
            rank_abs: (if rank_yesterday == [], do: nil, else: rank_yesterday.rank - message.rank)
          }
        end)
        {:ok, details}
    end
  end

  def get_rank_by_user_id(user_id) do
    {:ok, user_info} = User.query_user(user_id)
    time = case __MODULE__.pquery_sort_limit(%{}, [date: -1], 1) do
      [] -> nil
      res ->List.first(res).date.ms
    end
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [date: -1], 1) do
      [] ->
        case UserAi.get_newest_ai_by_userId(user_id) do
          {:error, _} ->
            {:error, detail = %{
              submit_count: 0,
              user_id: user_id,
              last_submit_date: nil,
              rank: 0,
              update_time: time,
              ai_name: nil,
              user_name: user_info.user_name,
              rank_abs: nil
            }}
          {:ok, res} ->
            date = case BattleResultTest.get_newest_time_by_user_id(user_id) do
              {:ok, date} ->
                date
              {:error, _} ->
                nil
            end
            {:ok, count} = BattleResultTest.count_submit(user_id)
              {:error, detail = %{
                submit_count: count,
                user_id: user_id,
                last_submit_date: date,
                rank: 0,
                update_time: time,
                ai_name: res.ai_name,
                user_name: user_info.user_name,
                rank_abs: nil
              }}
        end

      res ->
        {:ok, user_info_ai} = UserAi.get_newest_ai_by_userId(user_id)
        {:ok, cnt} = BattleResultTest.count_submit(user_id)
        time_query = Battle.Utils.GetTime24.get_24h_before_any_date(user_info_ai.create_time.ms)
        rank_yesterday =
          case __MODULE__.pquery2(%{user_id: user_id,date: time_query.date},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
            [] -> []
            res -> res
                   |> Enum.map(fn message ->
              message
              |> __MODULE__.to_raw()
            end)
                   |> List.first()
          end

        {:ok, %{
          user_id: user_id,
          rate: List.first(res).rate,
          ai_name: user_info_ai.ai_name,
          last_submit_date: user_info_ai.create_time.ms,
          update_time: time,
          submit_count: cnt,
          user_name: user_info.user_name,
          rank: List.first(res).rank,
          rank_abs: (if rank_yesterday == [], do: nil, else: rank_yesterday.rank - List.first(res).rank)
        }
      }
    end
  end

  def save_rank(user_id, ai_name, rate, rank) do
    current_time = Ejoy.Bson.utc_now()
    __MODULE__.psave(%{user_id: user_id, ai_name: ai_name, rate: rate, date: current_time, rank: rank})
  end

  def remove_rank(user_id) do
    __MODULE__.pdelete(%{user_id: user_id})
  end
end
