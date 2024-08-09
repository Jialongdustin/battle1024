defmodule UserAi do


    use Ejoy.Db

    @db "battle"
    @collection "user_ai"
    @indexes [
      {[user_id: 1], false}
    ]
    @cleanable false

    field :user_id, :integer, required: true
    field :ai_name, :string, required: true
    field :git_url, :string, required: true
    field :tag, :string, required: true
    field :create_time, :datetime, required: true



    def get_ai_list_by_userId(user_id) do
      __MODULE__.pquery2(%{user_id: user_id},expected_explain: %Mongo2.ExpectedExplain{indexes_plan: [[user_id: 1]]})
      |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
    end

    def insert_ai(user_id, ai_name, git_url, tag) do

      info = %{user_id: user_id, ai_name: ai_name, git_url: git_url, tag: tag,create_time: Ejoy.Bson.utc_now()}
      __MODULE__.psave(info)
#UserAi.insert_ai(1,"Biu","git.com","1.0")
#UserAi.get_ai_list_by_userId(1)

    end

    def clean_message(user_id) do
      __MODULE__.pdelete(%{user_id: user_id}, false)
    end


end
