defmodule Battle.Mongo.UserAi do

  use Ejoy.Db

  @db "battle"
  @collection "user_ai"
  @indexes [
    {[user_id: 1], true}
  ]
  @cleanable false

  field :user_id, :integer, required: true
  field :ai_name, :string, required: true
  field :git_url, :string, required: true
  field :tag, :string, required: true
  field :create_time, :datetime, required: true

  def get_newest_ai_by_userId(user_id)do
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [create_time: -1], 1) do
      nil->{:error,"Battle.UserAi error"}
      res ->{:ok,res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end)|> List.first()}
    end
  end

  def get_all_gits() do
    case __MODULE__.pquery(%{}) do
      nil ->{:error,"no user_info"}
      res ->{:ok,res|> Enum.map(fn message -> %{user_id: message.user_id, git_url: message.git_url, tag: message.tag} end)}
    end
  end


  def get_ai_list_by_userId(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      nil->{:error,"Battle.UserAi error"}
      res ->{:ok,res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end)}
    end
  end

  def insert_ai(user_id, ai_name, git_url, tag) do
    info = %{user_id: user_id, ai_name: ai_name, git_url: git_url, tag: tag, create_time: Ejoy.Bson.utc_now()}
    __MODULE__.psave(info)
  end

#UserAi.insert_ai(1,"Biu","git.com","1.0")
#UserAi.get_ai_list_by_userId(1)

  def clean_message(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end


end
