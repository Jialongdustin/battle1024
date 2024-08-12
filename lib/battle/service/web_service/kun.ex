defmodule Battle.Service.WebService.Kun do
  @kun_api_url "https://kunapi.ejoy.com"
  @query_namespace "platform-p11285"
  @userId "453574"
  @status_error 1
  @status_success 4

  alias ElixirSense.Log
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

  # Kun.get_build_tasks()
  def get_build_tasks() do
    path = "/api/env/#{@query_namespace}/buildTasks"
    %{"code" => 0, "data" => %{"buildTasks" => buildtasks}} = send_post(path, %{name: "battle-platform", currentPage: 1, pageSize: 5})
    # Enum.map(buildtasks, fn task -> {id: task.id, status: task.status}) 1 错误, 2 挂起中, 3 运行中, 4 完成
    buildtasks
  end

  def start_build() do
    case UserAi.get_all_gits() do
      {:error, message} ->
        {:error, "build failed"}
      {:ok, gits} ->
        gits
        |> Enum.map(fn info -> build_package(info) end)
    end
  end

  # Kun.build_package(%{user_id: "545", git_url: "git@gitlab.alibaba-inc.com:wilson.wb/platform-battle-test.git", tag: "master"})
  def build_package(info) do
    user_id = info.user_id
    git_url = info.git_url
    tag = info.tag
    path = "/api/env/#{@query_namespace}/buildTask"
    case send_put(path, %{name: "battle-platform", branch: tag, userId: @userId, method: 0, comment: "test"}) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        status = 0
        package_id = task.id
        build_result_check(package_id)
        %{user_id: user_id, package_id: package_id}
      _ ->
        build_package(info)
    end
  end

  def build_result_check(package_id) do
    :timer.sleep(10_000)
    case get_build_result(package_id) do
      @status_success ->
        :ok
      _ ->
        build_result_check(package_id)
    end
  end

  # Kun.get_build_result(10177896)
  def get_build_result(package_id) do
    path = "/api/env/#{@query_namespace}/buildTask?id=#{package_id}"
    %{"code" => 0, "data" => data} = send_get(path, %{})
    data.status
  end

  def send_post(path, params) do
    {:ok, resp} = Ejoy.HttpRPC.application_json_post(@kun_api_url <> path,
      params, [], make_headers(path, params))
    resp
  end

  def send_get(path, params) do
    {:ok, resp} = Ejoy.HttpRPC.json_get(@kun_api_url <> path,
    params, [], make_headers(path, params, "GET"))
    resp
  end

  def send_put(path, params) do
    {:ok, resp} = Ejoy.HttpRPC.json_put(@kun_api_url <> path,
      params, [], make_headers(path, params, "PUT"))
    resp
  end

  def make_headers(path, params, method \\ "POST") do
    kun_key = UnionConfig.product_get(:battle_cfg) |> Map.get(:kun_key)
    headers = %{
      "X-Kun-Version" => "v1.0",
      "X-Kun-Signature-Version" => "v1.0",
      "X-Kun-Signature-Method" => "HMAC-SHA1",
      "x-kun-signature-nonce" => UUID.uuid4(),
      "X-Kun-Access-Key" => kun_key.id,
      "Date" => DateTime.utc_now() |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT"),
      "Content-Md5" => cal_content_md5(Ejoy.Jiffy.encode!(params)),
      "Content-Type" => "application/json"
    }
    Map.put(headers, "Authorization", make_signature(path, headers, kun_key.secret, method))
    |> Enum.to_list()
  end

  def cal_content_md5(body) do
    :crypto.hash(:md5, body) |> Base.encode64()  # 进行md5哈希运算，然后转为base64编码格式
  end

  def make_signature(path, headers, secret, method) do
    sign_bytes = get_bytes_to_sign(path, headers, method)
    :crypto.mac(:hmac, :sha, secret, sign_bytes) |> Base.encode64()
  end

  def get_bytes_to_sign(path, headers, method) do
    kun_headers_bytes = get_kun_headers_bytes(headers)
    Enum.join([
      method,
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
