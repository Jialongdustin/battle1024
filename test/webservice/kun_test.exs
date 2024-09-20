defmodule BattleTest.KunTest do
  use ExUnit.Case
  import Mock

  alias Battle.Service.WebService.Kun

  test "start_build/0" do
    with_mock Battle.Mongo.UserAi, [:passthrough], [
      get_all_gits: fn ->
        {:ok, [%{user_id: "111", git_url: "git", tag: "tag"}]}
      end
    ] do
      with_mock Kun, [:passthrough], [
        change_config: fn _ ->
          %{user_id: "111", package_name: "package"}
        end
      ] do
        result = Kun.start_build()
        assert result = [%{user_id: "111", package_name: "package"}]
      end
    end
  end

  test "change_config/1 when git or tag error" do
    result = Kun.change_config(%{user_id: "123", git_url: "git@gitlab.alibaba-inc.com:Test_elixir/battle1024_python_3.12.5", tag: "dustin"})
    assert result == {:error, "git or tag illegal"}
  end

  test "build_result_check/1 returns :ok on success" do
    with_mock Kun, [:passthrough], [
      get_build_result: fn _ ->
        4
      end
    ] do
      result = Kun.build_result_check("111")
      assert result == :ok
    end
  end

  test "get_build_result/1" do
    with_mock Kun, [:passthrough], [
      send_get: fn _, _ ->
        %{"code" => 0, "data" => %{"task" => %{"status" => 4}}}
      end
    ] do
      result = Kun.get_build_result(:id)
      assert result == 4
    end
  end

  test "update_service_group/3 with success message" do
    with_mock Kun, [:passthrough], [
      send_post: fn _, _ ->
        %{"code" => 0, "data" => "success"}
      end
    ] do
      result = Kun.update_service_group(:services, :groupName, :groupKey)
      assert result == "success"
    end
  end

  test "create_deploy_task/1 with success message" do
    with_mock Kun, [:passthrough], [
      send_post: fn _, _ -> %{"code" => 0, "data" => %{"task" => %{"ID" => "10065"}}} end,
      get_deploy_result: fn _ -> %{"code" => 0, "data" => "success"} end
    ] do
      result = Kun.create_deploy_task(:services)
      assert result == %{"code" => 0, "data" => "success"}
    end
  end

  test "get_deploy_result/1 with success message" do
    with_mock Kun, [:passthrough], [
      send_get: fn _, _ ->
        %{"code" => 0, "data" => %{"task" => %{"services" => [%{"status" => "ready"}]}}}
      end
    ] do
      result = Kun.get_deploy_result(:id)
      assert result == {:ok, "deploy done"}
    end
  end

  test "create_uninstall_task/1 with success message" do
    with_mock Kun, [:passthrough], [
      send_post: fn _, _ ->
        %{"code" => 0, "data" => %{"task" => "success"}}
      end
    ] do
      result = Kun.create_uninstall_task(:services)
      assert result == "success"
    end
  end

  test "send_get/2 with success message" do
    with_mock Ejoy.HttpRPC, [:passthrough], [
      json_put: fn _, _, _, _ ->
        {:ok, "success"}
      end
    ] do
      
    end
  end
end
