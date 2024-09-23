defmodule Battle.Service.WebService.Kun do
  @kun_api_url "https://kunapi.ejoy.com"
  # @kun_api_url "https://kundevapi.ejoy.com"  kun测试环境
  @query_namespace "plat1024-platformbattle"
  @userId "453574"
  @status_success 4
  @status_failure 1
  @productKey "plat1024"
  @build_config_name "AI-player"

  alias ElixirSense.Log
  alias Battle.Mongo.UserAi
  # alias Battle.Service.WebService.Kun
  # Logger.configure(level: :none)

  def start_build() do
    case UserAi.get_all_gits() do
      {:error, message} ->
        {:error, "no git submit success"}
      {:ok, gits} ->
        gits
        |> Enum.map(fn info -> change_config(info) end)
    end
  end

  # Kun.change_config(%{user_id: "123", git_url: "git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5.git", tag: "dustin"})
  def change_config(info, attempt \\ 0) do
    user_id = info.user_id
    git_url = info.git_url
    tag = info.tag
    path = "/api/v2/product/#{@productKey}/buildConfig/#{@build_config_name}"
    case Battle.Service.WebService.Kun.send_put(path, %{autoBuild: true, gitRefsType: 0, gitUrl: git_url, refs: tag}) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        # build_package(info)
        package_id = task["id"]
        package_name = task["name"]
        case build_result_check(package_id) do
          :ok ->
            %{user_id: user_id, package_name: package_name}
          :error ->
            {:error, "build failed"}
        end

      {:error, 400} ->
        {:error, "git or tag illegal"}

      {:error, 500} when attempt < 3 ->
        change_config(info, attempt + 1)

      {:error, 500} ->
        {:kun_error, "received 500 error from kun after 3 attempts"}
    end
  end

  # def build_package(info) do
  #   tag = info.tag
  #   user_id = info.user_id
  #   build_path = "/api/env/#{@query_namespace}/buildTask"
  #   case send_put(build_path, %{name: @build_config_name, branch: tag, userId: @userId, method: 0}) do
  #     %{"code" => 0, "data" => %{"task" => task}} ->
  #       package_id = task["id"]
  #       package_name = task["name"]
  #       build_result_check(package_id)
  #       %{user_id: user_id, package_name: package_name}
  #     _ ->
  #       build_package(info)
  #   end
  # end

  # Kun.build_result_check(12024311)
  def build_result_check(package_id) do
    :timer.sleep(2_000)
    case Battle.Service.WebService.Kun.get_build_result(package_id) do
      @status_success ->
        :ok
      @status_failure ->
        :error
      _ ->
        build_result_check(package_id)
    end
  end

  # Kun.get_build_result(10179621)
  def get_build_result(package_id) do
    path = "/api/env/#{@query_namespace}/buildTask?id=#{package_id}"
    %{"code" => 0, "data" => %{"task" => task}} = Battle.Service.WebService.Kun.send_get(path, %{})
    task["status"]
  end

  # # Kun.create_service_group()
  # def create_service_group(services) do
  #   # package_msgs = start_build()
  #   id = UUID.uuid4()
  #   services_name = "battle-players#{id}"
  #   services_key = "players#{id}"
  #   groups = [
  #     %{
  #       "name": services_name,
  #       "key": services_key,
  #       "schdule": "",
  #       "services": services
  #     }
  #   ]
  #   content = %{groups: groups}
  #   path = "/api/env/#{@query_namespace}/service/create"
  #   case send_post(path, content) do
  #     %{"code" => 0, "data" => data} ->
  #       data
  #   end
  #   {:ok, %{name: services_name, key: services_key}}
  # end

  # Kun.update_service_group()
  def update_service_group(services, groupName, groupKey, attempt \\ 0) do
    path = "/api/env/#{@query_namespace}/serviceGroup/sync"
    groups = [
      %{
        "name": groupName,
        "key": groupKey,
        "schdule": "",
        "services": services
      }
    ]
    case Battle.Service.WebService.Kun.send_post(path, %{groups: groups}) do
      %{"code" => 0, "data" => data} ->
        data

      {:error, 500} when attempt < 3 ->
        update_service_group(services, groupName, groupKey, attempt + 1)

      {:error, 500} ->
        {:error, "received 500 error from kun after 3 attempts"}
    end
  end

  # Kun.create_deploy_task(services)
  def create_deploy_task(services, attempt \\ 0) do
    path = "/api/env/#{@query_namespace}/createDeployTask"
    content = %{
      "services": services,
      "userId": @userId
    }
    case Battle.Service.WebService.Kun.send_post(path, content) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        id = task["ID"]
        Battle.Service.WebService.Kun.get_deploy_result(id)

      {:error, 500} when attempt < 3 ->
        create_deploy_task(services, attempt + 1)

      {:error, 500} ->
        {:error, "received 500 error from kun after 3 attempts"}
    end
  end

  # Kun.get_deploy_result(11464803)
  def get_deploy_result(id) do
    path = "/api/env/#{@query_namespace}/task?id=#{id}"
    case Battle.Service.WebService.Kun.send_get(path, %{}) do
      %{"code" => 0, "data" => %{"task" => %{"services" => services}}} ->
        case Enum.all?(services, fn service -> service["status"] == "ready" end) do
          true ->
            {:ok, "deploy done"}
          false ->
            :timer.sleep(2_000)
            get_deploy_result(id)
        end
      _ ->
        {:error, "id not exists"}
    end
  end

  # Kun.create_uninstall_task(%{"service_group" => "plat1024", "service_name" => "battle-service"})
  def create_uninstall_task(services) do
    path = "/api/env/#{@query_namespace}/createUninstallTask"
    content = %{
      "services": services,
      "userId": @userId
    }
    case Battle.Service.WebService.Kun.send_post(path, content) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        task
      _ ->
        :error
    end
  end

  # # Kun.get_service_stage(["battle-players1", "battle-players2"], "battle-player-python")
  # def get_service_stage(groupName, appName) do
  #   path = "/api/env/#{@query_namespace}/services"
  #   content = %{
  #     currentPage: 1,
  #     pageSize: 1,
  #     servicesGroups: [groupName],
  #     apps: [appName]
  #   }
  #   case send_post(path, content) do
  #     %{"code" => 0, "data" => %{"services" => services}} ->
  #       # List.first(services)["stage"]
  #       services
  #     _ ->
  #       {:error, "something wrong"}
  #   end
  # end

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
    case Ejoy.HttpRPC.json_put(@kun_api_url <> path,
      params, [], make_headers(path, params, "PUT")) do
        {:ok, resp} ->
          resp
        {:fail, reason} ->
          {:error, reason}
      end
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
    message = :crypto.hash(:md5, body) |> Base.encode64()  # 进行md5哈希运算，然后转为base64编码格式
    message
  end

  def make_signature(path, headers, secret, method) do
    sign_bytes = get_bytes_to_sign(path, headers, method)
    message = :crypto.mac(:hmac, :sha, secret, sign_bytes) |> Base.encode64()
    message
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
