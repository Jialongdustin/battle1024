defmodule Battle.Service.BattleService.RoomSupervisorTest do
  use DynamicSupervisor

  alias Battle.Service.BattleService.RoomServer
  alias Battle.Service.WebService.WebSocketHandler
  alias Battle.Utils.Token

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:pid_info_test, [:named_table, :public, read_concurrency: true])
    :ets.new(:user_session, [:named_table, :public, read_concurrency: true])
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def init_game() do

    contest_id = UUID.uuid4()
    {:ok,token_white} = Token.generate_token(10, contest_id)
    {:ok,token_black} = Token.generate_token(24, contest_id)
    child_spec_server = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [%{white: 10, black: 24, contest_id: contest_id}]},
      restart: :transient,
      type: :worker
    }
#    :ets.insert(:user_session,{contest_id,session})
    DynamicSupervisor.start_child(__MODULE__, child_spec_server)
#    {:ok, %{token_white: token_white, token_black: token_black}}
    detail = %{
      token_white: token_white,
      token_black: token_black
    }
#    send(session,{:init_message,detail})
  end

  def query(caller, user_id, contest_id) do
    [{pid, _}] = Registry.lookup(Battle.RoomRegistry, contest_id)
    case RoomServer.query(pid, user_id) do
      {:ok, detail} ->
        # 当前询问回合，写回成功
        IO.inspect(detail)
        {:ok, detail}
      {:error, detail} ->
        :ets.insert(:pid_info, {contest_id, caller})
        # 不是当前询问回合，写回错误
        {:error, detail}
    end
  end

  def movement(moves, user_id, contest_id) do
    case Registry.lookup(Battle.RoomRegistry, contest_id) do
      [{pid, _}] ->
        case RoomServer.movement(pid, user_id, moves) do
          {:ok, success_detail} ->
            # 将your_step改为opponent_step
            if success_detail.winner do
              RoomServer.terminate_game(pid)
            end
            case :ets.lookup(:pid_info, contest_id) do
              [] -> # 对方没有查询
                {:ok, success_detail}
              [{_, dest}] -> #对方查询棋盘状态
                new_detail = %{
                  code: 10003,
                  move_detail: success_detail.move_detail,
                  board: success_detail.board,
                  winner: success_detail.winner
                }
                send(dest, {:query, new_detail})
                {:ok, success_detail}
            end

          {:error, error_detail} ->
            {:error, error_detail}
        end
      [] ->
        {:error, "room not found"}
    end
  end
end
