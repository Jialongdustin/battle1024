defmodule BattleTest.TournamentTest do
  use ExUnit.Case
  import Mock

  alias Battle.Service.BattleService.Tournament
  alias Battle.Service.BattleService.ThreadPool

  test "start tournament" do
    with_mock Battle.Service.WebService.Kun, [:passthrough], [
      start_build: fn ->
        [%{user_id: "111", package_name: "safalfasl"}, %{user_id: "222", package_name: "skasfaf"}]
      end
    ] do
      Tournament.start_tournament()
      assert length(ThreadPool.get_state().workers) == 2
    end
  end
end
