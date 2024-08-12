defmodule Battle.Utils.Token do

  require Logger

  def generate_token(account) do
    user = "battle_user"
    moment_token = Holo.Moment.Token.new(user, account, 2) |> to_string()
    Logger.info(moment_token)
    {:ok, moment_token}

  end

  def verify_token(moment_token) do
    case Ejoy.Plug.Authenticate.Moment.auth_token(moment_token) do
      {:ok, user_info}->
        case user_info.ext.account_id do
          "battle_user" ->
            {:ok, user_info.user_id}
          _ ->{:error, "invalid token"}
        end
      _ ->
        {:error, "permission deny"}
    end
  end

end
