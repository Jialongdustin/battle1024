defmodule Battle.Mongo.UserAi do

  use Ejoy.Db

  @db "battle"
  @collection "user_ai"
  @indexes [
    {[user_id: 1], false}
  ]
  @cleanable false

  field :user_id, :integer, required: true
  field :ai_name, :string, required: true
  field :git_url, :string, required: false
  field :tag, :string, required: false
  field :create_time, :datetime, required: false

  def get_newest_ai_by_userId(user_id)do
    case __MODULE__.pquery_sort_limit(%{user_id: user_id}, [create_time: -1], 1) do
      nil->{:error,"Battle.UserAi error"}
      res ->{:ok,res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end)|> List.first()}
    end
  end

  def get_ai_list_by_userId(user_id) do
    case __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]}) do
      nil->{:error,"Battle.UserAi error"}
      res ->{:ok,res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end)}
    end

  end

  def get_all_gits() do
    case __MODULE__.pquery(%{}) do
      nil ->{:error, "no user_info"}
      res ->{:ok, res|> Enum.map(fn message -> %{user_id: message.user_id, git_url: message.git_url, tag: message.tag} end)}
    end
  end

  def count_submit() do
    case __MODULE__.pcount(%{}) do
      {:ok, cnt} -> cnt
      _ -> 0
    end
  end

  def count_user(user_id) do
    case __MODULE__.pcount(%{user_id: user_id}) do
      {:ok, cnt} -> {:ok, cnt}
      _ -> {:error, 0}
    end
  end

  def get_newest_submit_time() do
    case __MODULE__.pquery_sort_limit(%{},[create_time: -1],1) do
      nil->{:error,"Battle.UserAi error"}
      res ->
        newest_info = res|> Enum.map(fn message -> message |> __MODULE__.to_raw() end)|> List.first()
        newest_info.create_time
    end
  end

  def insert_ai(user_id, ai_name) do
    info = %{
      user_id: user_id,
      ai_name: ai_name,
      create_time: Ejoy.Bson.utc_now()
    }
    __MODULE__.psave(info)
  end

  def update_git(user_id,tag,url) do
      {:ok,user_info} =get_newest_ai_by_userId(user_id)
      bson_id = user_info._id
      __MODULE__.pupdate(%{_id: bson_id},%{user_info | git_url: url, tag: tag})
  end


#UserAi.insert_ai(1,"Biu","git.com","1.0")
#UserAi.get_ai_list_by_userId(1)


  def clean_message(user_id) do
    __MODULE__.pdelete(%{user_id: user_id}, false)
  end


end
