defmodule Battle.Service.WebService.Auth do

  require Logger
  alias Battle.Mongo.User

  @client_id "10052"
  @client_secret "l3PUsNyV1WBfUwwFrSTLGw=="
  @verify_token_invalid_codes [
    10606, # code_not_match,
    10040, # code_not_valid
  ]

  @callback verify_code(String.t()) :: {:ok, map()} | {:error, any()}
  def verify_code(access_token) do
        url = "https://one.ejoy.com/api/oapi/user/get_user_info"
        params = %{
        access_token: access_token
        }
        {:ok, resp} = Ejoy.HttpRPC.application_json_post(url, params)
        case resp do
          %{
            "account" => account,
            "name" =>name
          } ->
            res =
              case User.query_user_by_account(account) do
                {:error, _} ->
                  user_id = UUID.uuid1()
                  User.save_user(user_id, account, name)
                  user_id
                {:ok, res} ->
                  res.user_id
              end
          Battle.Utils.Token.generate_token(res)
        %{"code" => code} ->
          {:error, code}
        end
  end
end
