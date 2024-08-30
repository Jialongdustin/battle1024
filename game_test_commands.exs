game_id = UUID.uuid4()
IO.puts("game_id: #{game_id}")
groupName = "battle-players"
groupKey = "plat1024-players"
appName = "battle-player-python"
alias Battle.Service.BattleService.RoomSupervisor
alias Battle.Service.BattleService.RoomServer
RoomSupervisor.init_game(10, 24, game_id, groupName, groupKey, appName)
[{pid, _}] = Registry.lookup(Battle.RoomRegistry, game_id)
{:ok, token_white} = Battle.Utils.Token.generate_token(10, game_id)
{:ok, token_black}= Battle.Utils.Token.generate_token(24, game_id)
IO.puts("Token White: #{token_white}")
IO.puts("Token Black: #{token_black}")
