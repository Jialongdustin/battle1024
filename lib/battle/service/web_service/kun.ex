defmodule Battle.Service.WebService.Kun do
  @kun_api_url "https://kunapi.ejoy.com"
  @query_namespace "plat1024-platformbattle"
  @userId "453574"
  @status_success 4
  @productKey "plat1024"
  @build_config_name "AI-player"
  @service_groups ["battle-players1", "battle-players2", "battle-players3", "battle-players4"]
  @appNames ["battle-player-python", "battle-player-java"]

  alias ElixirSense.Log
  alias Battle.UserAi
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
    %{"code" => 0, "data" => %{"buildTasks" => buildtasks}} = send_post(path, %{name: @build_config_name, currentPage: 1, pageSize: 5})
    # Enum.map(buildtasks, fn task -> {id: task.id, status: task.status}) 1 错误, 2 挂起中, 3 运行中, 4 完成
    buildtasks
  end

  def start_build() do
    case UserAi.get_all_gits() do
      {:error, message} ->
        {:error, "build failed"}
      {:ok, gits} ->
        gits
        |> Enum.map(fn info -> change_config(info) end)
    end
  end

  # Kun.build_package(%{user_id: "222", git_url: "git@gitlab.alibaba-inc.com:Test_elixir/docker_build.git", tag: "main"})
  def change_config(info) do
    user_id = info.user_id
    git_url = info.git_url
    tag = info.tag
    path = "/api/v2/product/#{@productKey}/buildConfig/#{@build_config_name}"
    case send_put(path, %{autoBuild: false, gitRefsType: 0, gitUrl: git_url, refs: tag}) do
      %{"code" => 0, "data" => data, "msg" => msg} ->
        build_package(info)
      _ ->
        change_config(info)
    end
  end

  def build_package(info) do
    tag = info.tag
    user_id = info.user_id
    build_path = "/api/env/#{@query_namespace}/buildTask"
    case send_put(build_path, %{name: @build_config_name, branch: tag, userId: @userId, method: 0}) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        package_id = task["id"]
        package_name = task["name"]
        build_result_check(package_id)
        %{user_id: user_id, package_name: package_name}
      _ ->
        build_package(info)
    end
  end

  def build_result_check(package_id) do
    :timer.sleep(300_000)
    case get_build_result(package_id) do
      @status_success ->
        :ok
      _ ->
        build_result_check(package_id)
    end
  end

  # Kun.get_build_result(10179621)
  def get_build_result(package_id) do
    path = "/api/env/#{@query_namespace}/buildTask?id=#{package_id}"
    %{"code" => 0, "data" => %{"task" => task}} = send_get(path, %{})
    task["status"]
  end

  # Kun.create_service_group()
  def create_service_group(services) do
    # package_msgs = start_build()
    id = UUID.uuid4()
    services_name = "battle-players#{id}"
    services_key = "players#{id}"
    groups = [
      %{
        "name": services_name,
        "key": services_key,
        "schdule": "",
        "services": services
      }
    ]
    content = %{groups: groups}
    path = "/api/env/#{@query_namespace}/service/create"
    case send_post(path, content) do
      %{"code" => 0, "data" => data} ->
        data
    end
    {:ok, %{name: services_name, key: services_key}}
  end

  # Kun.update_service_group()
  def update_service_group(services, groupName, groupKey) do
    path = "/api/env/#{@query_namespace}/serviceGroup/sync"
    groups = [
      %{
        "name": groupName,
        "key": groupKey,
        "schdule": "",
        "services": services
      }
    ]
    case send_post(path, %{groups: groups}) do
      %{"code" => 0, "data" => data} ->
        data
      _ ->
        update_service_group(services, groupName, groupKey)
    end
  end

  # Kun.create_deploy_task(%{contest_id: "111", package_name: "plat1024-battle-players:20240815173843"})
  def create_deploy_task(services) do
    path = "/api/env/#{@query_namespace}/createDeployTask"
    content = %{
      "services": services,
      "userId": @userId
    }
    case send_post(path, content) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        id = task["ID"]
        :timer.sleep(10_000)
        get_deploy_result(id)
      _ ->
        create_deploy_task(services)
    end
  end

  # Kun.get_deploy_result(11464803)
  def get_deploy_result(id) do
    path = "/api/env/#{@query_namespace}/task?id=#{id}"
    case send_get(path, %{}) do
      %{"code" => 0, "data" => %{"task" => %{"services" => services}}} ->
        case Enum.all?(services, fn service -> service["status"] == "ready" end) do
          true ->
            {:ok, "deploy done"}
          false ->
            :timer.sleep(10_000)
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
    case send_post(path, content) do
      %{"code" => 0, "data" => %{"task" => task}} ->
        task
      _ ->
        :error
    end
  end

  #  # Kun.create_uninstall_task_test(%{"service_group" => "plat1024", "service_name" => "battle-service"})
  #  def create_uninstall_task_test(info) do
  #   path = "/api/env/#{@query_namespace}/createUninstallTask"
  #   content = %{
  #     "services": [
  #       %{
  #         "serviceGroup": info["service_group"],
  #         "service": info["service_name"],
  #         "deleteExclusivePvc": false
  #       }
  #     ],
  #     "userId": @userId
  #   }
  #   case send_post(path, content) do
  #     %{"code" => 0, "data" => %{"task" => task}} ->
  #       task
  #     _ ->
  #       :error
  #   end
  # end

  # Kun.get_idle_service()
  def get_idle_service() do
    Enum.flat_map(@service_groups, fn groupName ->
      Enum.filter(@appNames, fn appName ->
        get_service_stage(groupName, appName) == "idle"
      end)
      |> Enum.map(fn appName -> {groupName, appName} end)
    end)
    |> List.first()
  end

  # Kun.get_service_stage()
  def get_service_stage(groupName, appName) do
    path = "/api/env/#{@query_namespace}/services"
    content = %{
      currentPage: 1,
      pageSize: 1,
      servicesGroups: [groupName],
      apps: [appName]
    }
    case send_post(path, content) do
      %{"code" => 0, "data" => %{"services" => services}} ->
        List.first(services)["stage"]
      _ ->
        {:error, "something wrong"}
    end
  end

  # Kun.get_app_config_list("battle-player")
  def get_app_config_list(appName) do
    path = "/api/env/#{@query_namespace}/appConfig?appName=#{appName}"
    case send_get(path, %{}) do
      %{"code" => 0, "data" => %{"appConfigs" => appConfigs}} ->
        appConfigs
    end
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
    message = :crypto.hash(:md5, body) |> Base.encode64()  # 进行md5哈希运算，然后转为base64编码格式
    IO.puts("Date:")
    IO.inspect DateTime.utc_now() |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
    IO.puts("md5:")
    IO.inspect(message)
    message
  end

  def make_signature(path, headers, secret, method) do
    sign_bytes = get_bytes_to_sign(path, headers, method)
    message = :crypto.mac(:hmac, :sha, secret, sign_bytes) |> Base.encode64()
    IO.puts("signature:")
    IO.inspect(message)
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
