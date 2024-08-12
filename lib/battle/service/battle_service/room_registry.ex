defmodule Battle.Service.BattleService.RoomRegistry do
  use Registry, keys: :unique, name: Battle.Service.BattleService.RoomRegistry
end
