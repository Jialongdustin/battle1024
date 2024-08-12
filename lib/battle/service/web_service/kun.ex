defmodule Battle.Service.WebService.Kun do
  @kun_api_url "https://kunapi.ejoy.com"
  @query_namespace "platform-p11285"
  @userId "453574"

  alias Battle.Mongo.UserAi
  # alias Battle.Service.WebService.Kun
  # Logger.configure(level: :none)

  def list_envs() do
    path = "/api/env/#{@query_namespace}/envs"
    %{"code" => 0, "data" => %{"envs" => envs}} = send_post(path, %{})
    envs
  end

  def get_instances(ns, apps) do
    path = "/api/env/#{ns}/instances"
    %{"code" => 0, "data" => %{"instances" => instances}} = send_post(path, %{apps: apps})
    instances
  end

  def start_build() do
    case UserAi.get_all_gits() do
      {:error, message} ->
        {:error, "build failed"}
      {:ok, gits} ->
        gits
        |> Enum.each(fn info -> build_package(info) end)
    end
  end

  # %{user_id: "545", git_url: "", tag: "master"}
  def build_package(info) do
    user_id = info.user_id
    git_url = info.git_url
    tag = info.tag
    path = "/api/env/#{@query_namespace}/buildTask"
    %{"code" => 0, "data" => %{"task" => task}} = send_put(path, %{name: "battle-platform", branch: "#{tag}", userId: @userId, method: 0})
    %{"user_id" => user_id, "task_id" => task.id}
  end

  def send_post(path, params) do
    {:ok, resp} = Ejoy.HttpRPC.application_json_post(@kun_api_url <> path,
      params, [], make_headers(path, params))
    resp
  end

  def send_put(path, params) do
    {:ok, resp} = Ejoy.HttpRPC.json_put(@kun_api_url <> path,
      params, [], make_headers(path, params))
    resp
  end

  def make_headers(path, params) do
    kun_key = UnionConfig.product_get(:battle_cfg) |> Map.get(:kun_key)
    # admin_center_cfg: %{
    #   TEST: %{
    #     ansible_products: %{
    #     },
    #     require_admin_gate_version: "202404181500",
    #     kun_key: %{
    #       id: "test_id",
    #       secret: "test_secret"
    #     }
    #   }
    # }
    headers = %{
      "X-Kun-Version" => "v1.0",
      "X-Kun-Signature-Version" => "v1.0",
      "X-Kun-Signature-Method" => "HMAC-SHA1",
      "x-kun-signature-nonce" => UUID.uuid4(),
      "X-Kun-Access-Key" => kun_key.id,
      "Date" => DateTime.utc_now() |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT"),
      "Content-Md5" => cal_content_md5(Ejoy.Jiffy.encode!(params))
    }
    Map.put(headers, "Authorization", make_signature(path, headers, kun_key.secret))
    |> Enum.to_list()
  end

  def cal_content_md5(body) do
    :crypto.hash(:md5, body) |> Base.encode64()  # 进行md5哈希运算，然后转为base64编码格式
  end

  def make_signature(path, headers, secret) do
    sign_bytes = get_bytes_to_sign(path, headers)
    :crypto.mac(:hmac, :sha, secret, sign_bytes) |> Base.encode64()
  end

  def get_bytes_to_sign(path, headers) do
    kun_headers_bytes = get_kun_headers_bytes(headers)
    Enum.join([
      "POST",
      "application/json",
      headers["Content-Md5"],
      headers["Date"],
      kun_headers_bytes,
      path,
    ], "\n")
  end

  def get_kun_headers_bytes(headers) do
    for {k, v} <- headers, String.starts_with?(String.downcase(k), "x-kun") do
      {k |> String.downcase(), v}
    end
    # 会转成列表
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
    |> Enum.join("\n")
  end
end
