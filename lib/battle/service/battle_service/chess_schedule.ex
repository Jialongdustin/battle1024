defmodule Battle.Service.BattleService.ChessSchedule do
  alias Battle.Service.BattleService.RoomSupervisor
  alias Battle.Service.WebService.Kun

  def generate_pairs(players) do
    players
    |> Enum.combinations(2)
    |> Enum.map(&assign_games(&1))
  end

  defp assign_games([p1, p2]) do
    [
      Task.async(fn -> RoomSupervisor.join_game(p1, p2) end),
      Task.async(fn -> RoomSUpervisor.join_game(p2, p1) end)
    ]
  end

  def schedule_battle(players) do
    players
    |> generate_pairs()
    |> List.flatten()
    |> Enum.each(&Task.await/1)
  end
end
