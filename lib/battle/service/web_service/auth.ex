defmodule Battle.Service.WebService.Auth do

  require Logger

  @client_id "10052"
  @client_secret "l3PUsNyV1WBfUwwFrSTLGw=="
  @verify_token_invalid_codes [
    10606, # code_not_match,
    10040, # code_not_valid
  ]

  @callback verify_code(String.t()) :: {:ok, map()} | {:error, any()}
  def verify_code(code) do
    params =  %{
      client_id: @client_id,
      client_secret: @client_secret,
      grant_type: "authorization_code",
      code: code
    }
    url = "https://one.ejoy.com/api/oauth_v3/token"

    {:ok, resp} = Ejoy.HttpRPC.application_json_post(url, params)
    Logger.info(resp)

    case resp do
      %{
        "code" => 0, "access_token" => access_token, "account" => account,
        "expires_in" => expires_in

      } ->
       {:ok, moment_token} = Battle.Utils.Token.generate_token(account)
        from_product_code = Map.get(resp, "from_product_code")
        {:ok,
          %{
            moment_token: moment_token
          }
        }
      %{"code" => code} when code in @verify_token_invalid_codes ->
        one_resp = %{
          code: code,
          message: Map.get(resp, "message")
        }
        {:error, %{one_resp: one_resp}}
    end

  end
end
