defmodule Battle.Mongo.RankList do
  use Ejoy.Db

  alias Battle.Mongo.UserAi

  @db "battle"
  @collection "rank_list"
  @indexes [
    {[rate: 1], false},
    {[user_id: 1],false}
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
          %{
            ai_name: message.ai_name,
            user_id: message.user_id,
            rate: message.rate
          }
        end)
        {:ok, details}
    end
  end

  def get_rank_by_user_id(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      [] -> {:error, "user_id error"}
      res ->

        detail =
          case res|>Enum.map(fn message -> message|> __MODULE__.to_raw() end)|>List.first() do
            nil ->
              {:ok, user_info} = Battle.Mongo.UserAi.get_newest_ai_by_userId(user_id)

              {_,cnt} = UserAi.count_user(user_id)
              %{
                user_id: user_id,
                rate: 0,
                last_submit_date: user_info.create_time.ms,
                count: cnt
              }
            info ->
              IO.inspect(info)
              {:ok,user_info} = UserAi.get_newest_ai_by_userId(user_id)
              IO.inspect(user_info)
              {_,cnt} = UserAi.count_user(user_id)

              query = %{
                rate: %{
                  "$gte": info.rate
                }
              }
              {:ok,rank} = __MODULE__.pcount(query)

              %{
                user_id: user_id,
                rate: info.rate,
                ai_name: user_info.ai_name,
                last_submit_date: user_info.create_time,
                count: cnt,
                rank: rank

              }
          end

        {:ok, detail}
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
