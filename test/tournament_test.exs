defmodule BattleTest.TournamentTest do
  use ExUnit.Case
  import Mock

  alias Battle.Service.BattleService.Tournament

  test "schedules tournament today" do
    now = DateTime.utc_now()
    noon = "#{Date.to_string(now)} 04:00:00"
    expected_time = noon <> "Z"

    with_mock DateTime, [:passthrough], [
      from_iso8601: fn ^expected_time -> {:ok, DateTime.add(now, 3_600_000, :millisecond), 0} end
    ] do
      ref = Tournament.schedule_tournament()
      assert is_reference(ref)
    end
  end

  test "schedules tournament tomorrow" do
    now = DateTime.utc_now()
    noon = "#{Date.to_string(now)} 04:00:00"
    expected_time = noon <> "Z"

    with_mock DateTime, [:passthrough], [
      from_iso8601: fn ^expected_time -> {:ok, DateTime.add(now, -3_600_000, :millisecond), 0} end
    ] do
      ref = Tournament.schedule_tournament()
      assert is_reference(ref)
    end
  end

  test "initiate_tournament_logic with players" do
    with_mock Battle.Service.WebService.Kun, [:passthrough], [
      start_build: fn ->
        [%{user_id: "user1", package_name: "package1"}, %{user_id: "user2", package_name: "package2"}]
      end
    ] do
      with_mock Battle.Service.BattleService.ThreadPool, [:passthrough], [
        add_task: fn _ ->
          {:ok, "begin"}
        end
      ] do
        response = Tournament.initiate_tournament_logic()
        assert response == {:ok, "start tournament"}
      end
    end
  end

  test "initiate_tournament_logic without enough players" do
    with_mock Battle.Service.WebService.Kun, [:passthrough], [
      start_build: fn ->
        [%{user_id: "user1", package_name: "package1"}]
      end
    ] do
      response = Tournament.initiate_tournament_logic()
      assert response == {:ok, "start tournament"}
    end
  end

  test "initiate_tournament_logic when kun error" do
    with_mock Battle.Service.WebService.Kun, [:passthrough], [
      start_build: fn ->
       {:error, :some_reason}
      end
    ] do
      response = Tournament.initiate_tournament_logic()
      assert response == {:error, :some_reason}
    end
  end

  test "check win rate update behavior" do
    with_mock Battle.Mongo.BattleResult, [:passthrough], [
      get_battle_results_within_24_hour: fn ->
        {:ok, [%{}, %{}]}
      end
    ] do
      games = 2
      with_mock Battle.Service.WebService.RankList, [:passthrough], [
        get_battle_info: fn ->
          {:ok, [%{user_id: "111", rate: 0.8, ai_name: "niubi"}]}
        end
      ] do
          result = Tournament.update_win_rate(games)
          Battle.Mongo.RankList.remove_rank("111")
          assert length(result) == 1
      end
    end
  end

  test "handle_info/2 to start toounament" do
    with_mock Tournament, [:passthrough], [
      schedule_tournament: fn -> {:ok, "start schedule"} end,
      initiate_tournament_logic: fn -> {:ok, "start tournament"} end
    ] do
      send(Tournament, :start_tournament)
      :timer.sleep(50)
    end
  end

end
