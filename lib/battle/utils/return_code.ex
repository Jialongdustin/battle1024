defmodule Battle.Utils.ReturnCode do
  defmacro __using__(_options) do
    return_code_module = __MODULE__

      quote do
        use Ejoy.JsonResp, return_code_module: unquote(return_code_module)
        message_code_2(:login_required, 100, "需要登录", :client_error)
        message_code_2(:one_token_invalid, 101, "one token错误", :client_error)
        message_code_2(:invalid_auth_key, 102, "child auth key错误", :client_error)
        message_code_2(:one_code_error, 103, "one code错误", :client_error)
        message_code_2(:login_state_not_match, 104, "auth state不匹配", :client_error)
        message_code_2(:exchange_one_code_fail, 105, "交换one code失败", :client_error)
        message_code_2(:patch_user_opts_empty, 106, "用户设置选项为空", :client_error)
      end
  end
end
