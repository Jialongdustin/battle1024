defmodule Battle.Mongo.RankList do
  use Ejoy.Db

  alias Battle.Mongo.UserAi
  alias Battle.Mongo.User
  alias Battle.Mongo.BattleResultTest

  @db "battle"
  @collection "rank_list"
  @indexes [
    {[rate: 1], false},
    {[user_id: 1], false}
  ]
  @cleanable false

  field :user_id, :string, required: true
  field :ai_name, :string, required: true
  field :rate, :float, required: true
  field :date, :datetime, required: true

  def get_rank_list(page, limit) do
    time_query = Battle.Utils.GetTime24.get_time()
    case __MODULE__.pquery_sort_limit(time_query, [rate: -1], limit, page*limit) do
      [] -> {:error, "empty rank list" }
      res ->
        details = res |> Enum.map(fn message ->
          message = message |> __MODULE__.to_raw()
          {:ok, user_info} = User.query_user(message.user_id)
          %{
            ai_name: message.ai_name,
            user_id: message.user_id,
            rate: message.rate,
            avatar: user_info.avatar
          }
        end)
        {:ok, details}
    end
  end

  def get_rank_by_user_id(user_id) do
    {:ok, user_info} = User.query_user(user_id)
    case __MODULE__.pquery2(%{user_id: user_id}, expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] ->
        case UserAi.get_newest_ai_by_userId(user_id) do
          {:error, _} ->
            {:error, detail = %{
              submit_count: 0,
              user_id: user_id,
              last_submit_date: nil,
              rank: 0,
              ai_name: nil,
              user_name: user_info.user_name
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
                ai_name: res.ai_name,
                user_name: user_info.user_name
              }}
        end

      res ->
        {:ok, user_info_ai} = UserAi.get_newest_ai_by_userId(user_id)
        {:ok, cnt} = UserAi.count_user(user_id)
        query = %{
          rate: %{
            "$gte": List.first(res).rate
          }
        }
        {:ok, rank} = __MODULE__.pcount(query)

        {:ok, %{
          user_id: user_id,
          rate: List.first(res).rate,
          ai_name: user_info_ai.ai_name,
          last_submit_date: user_info_ai.create_time.ms,
          count: cnt,
          user_name: user_info.user_name,
          rank: rank
        }
      }
    end
  end

  def save_rank(user_id, ai_name, rate) do
    current_time = Ejoy.Bson.utc_now()
    __MODULE__.psave(%{user_id: user_id, ai_name: ai_name, rate: rate, date: current_time})
  end

  def remove_rank(user_id) do
    __MODULE__.pdelete(%{user_id: user_id})
  end
end
