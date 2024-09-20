defmodule Battle.Utils.Token do

  require Logger

  def generate_token(account) do
    user = "battle_user"
    {:ok,moment_token,token_info} = Ejoy.MomentToken.new_token_info(1, 1, account, %{})
    Logger.info(moment_token)
    {:ok, moment_token}
#WB01483622
  end

  def generate_token(user_id, game_id) do
#    user_info = %{user_id: user_id,contest_id: contest_id}
    {:ok,moment_token,token_info} = Ejoy.MomentToken.new_token_info(1, 1, user_id, %{game_id: game_id})

    {:ok, moment_token}
  end

  def verify_token(moment_token) do
    case Ejoy.MomentToken.Service.auth_token(moment_token) do
      {:ok, user_info}->
        {:ok, user_info.user_id}
      _ ->
        {:error, "permission deny"}
    end
  end

  def verify_token_battle(moment_token) do
    case Ejoy.MomentToken.Service.auth_token(moment_token) do
      {:ok, user_info}->
        Logger.info(user_info)
        {:ok, user_info}
      _ ->
        {:error, "permission deny"}
    end
  end

end
