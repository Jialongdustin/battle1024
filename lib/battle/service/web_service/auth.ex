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
#    params =  %{
#      client_id: @client_id,
#      client_secret: @client_secret,
#      grant_type: "authorization_code",
#      code: code,
#      product_code: "P11387",
#      product_secret: "U9e8ZB5x46+f6NR4Gxjl0A=="
#    }
#    url = "https://one.ejoy.com/api/oauth_v3/token"
#    IO.inspect(url)
#    IO.inspect(params)
##    {:ok, resp} = Ejoy.HttpRPC.application_json_post(url, params)
#    resp = 1
#    IO.inspect("=========")
    url = "https://one.ejoy.com/api/oapi/user/get_user_info"
    params = %{
      access_token: access_token
    }
    Logger.info(params)
    {:ok, resp} = Ejoy.HttpRPC.application_json_post(url, params)
    Logger.info(resp)
    case resp do
      %{
        "account" => account,
        "name" => name
      } ->
        res =
          case User.query_user(account) do
            {:error, _} ->
              user_id = UUID.uuid1()
              User.save_user(user_id, account, name)
              user_id
            {:ok, res} ->
              res.user_id
          end
          Battle.Utils.Token.generate_token(res)
      %{"code" => code} when code in @verify_token_invalid_codes ->
        one_resp = %{
          code: code,
          message: Map.get(resp, "message")
        }
        {:error, one_resp}
    end

  end
end
