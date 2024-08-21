defmodule Battle.Mongo.RankList do
  use Ejoy.Db

  require Logger

  alias Battle.Mongo.UserAi
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
    time_query = Battle.Utils.GetTime24.get_time()
    Logger.info(time_query)
    case __MODULE__.pquery_sort(time_query,[rate: -1]) do
      nil -> {:error, "empty rank list" }
      res ->
        details = res |> Enum.map(fn message ->
          message = message |> __MODULE__.to_raw()
          {_, ai_info} = UserAi.get_newest_ai_by_userId(message.user_id)

          %{
            ai_name: ai_info.ai_name,
            use_id: ai_info.user_id,
            rate: message.rate
          }
        end)

        {:ok, details}
    end
  end

  def get_rank_by_user_id(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      nil ->{:error, "user_id error"}
      res ->
        detail =
          case res|>Enum.map(fn message -> message|> __MODULE__.to_raw() end) do
            [] ->
              {:ok,user_info} = Battle.Mongo.UserAi.get_newest_ai_by_userId(user_id)

              {_,cnt} = UserAi.count_user(user_id)
              %{
                user_id: user_id,
                rate: 0,
                last_submit_date: user_info.create_time,
                count: cnt
              }
            info ->
              {:ok,user_info} = UserAi.get_newest_ai_by_userId(user_id)

              {_,cnt} = UserAi.count_submit(user_id)
              %{
                user_id: user_id,
                rate: info.rate,
                last_submit_date: user_info.create_time,
                count: cnt
              }
          end

        {:ok, detail}
    end
  end

  def save_rank(user_id, ai_name, rate) do
    current_time = Ejoy.Bson.utc_now()
    __MODULE__.psave(%{user_id: user_id, ai_name: ai_name, rate: rate, date: current_time})
    #UserAi.insert_ai(1,"Biu","git.com","1.0")
    #UserAi.get_ai_list_by_userId(1)

  end

end
