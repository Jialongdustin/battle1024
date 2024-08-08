defmodule UserAi do
  @moduledoc false

    use Ejoy.Db

    @db "battle"
    @collection "User_Ai"
    @indexes [
      {[user_id: 1], false}
    ]
    @cleanable false

    field :_id, :Object_id
    field :ai_name, :string
    field :git_url, :string
    field :tag, :string

    def get_ai_list_by_userId(user_id) do
      __MODULE__.pquery(%{_id: user_id})
      |> Enum.map(fn message ->
        message |> __MODULE__.to_raw()
      end)
    end

    def insert_ai(user_id, ai_name, git_url, tag) do
      __MODULE__.psave(%{_id: user_id, ai_name: ai_name, git_url: git_url, tag: tag})
    end

    def clean_message(room_name) do
      __MODULE__.pdelete(%{chatroom_name: room_name}, false)
    end


end
