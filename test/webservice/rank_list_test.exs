defmodule BattleTest.WebService.RankListTest do
  use ExUnit.Case
  import Mock
  #  doctest Battle.BattleDfs
  doctest Battle.Service.WebService.RankList
  alias Battle.Service.WebService.Auth
  alias Battle.Utils.Token
  alias Battle.Mongo.User
  alias Battle.Mongo.UserAi

  test "calculate win rate" do
    UserAi.insert_ai("1","hahaha")
    UserAi.insert_ai("123","Biu biu biu~~!!")
    UserAi.insert_ai("2","wawawawa")
    UserAi.insert_ai("456","Biu")
    # 模拟函数返回一个正确的列表
    with_mock Battle.Mongo.BattleResult, [:passthrough],
      get_battle_results_within_24_hour: fn ->
        {:ok,
         [
           %{
             game_id: "123212",
             memory_cost_2: ["11", "22"],
             time_cost_2: [11, 22],
             total_step_2: [20, 30],
             user_id_2: ["123", "456"],
             winner: "123"
           },
           %{
             date: ~U[2024-08-28T06:26:23Z],
             early_hand: "456",
             game_id: "123212",
             memory_cost_2: ["11", "22"],
             time_cost_2: [11, 22],
             total_step_2: [20, 30],
             user_id_2: ["123", "456"],
             winner: "456"
           },
           %{
             date: ~U[2024-08-28T06:26:43Z],
             early_hand: "2",
             game_id: "12dss23",
             memory_cost_2: ["11", "22"],
             time_cost_2: [11, 22],
             total_step_2: [20, 30],
             user_id_2: ["1", "2"],
             winner: "1"
           },
           %{
             date: ~U[2024-08-28T06:27:11Z],
             early_hand: "1",
             game_id: "12dss231",
             memory_cost_2: ["11", "22"],
             time_cost_2: [11, 22],
             total_step_2: [20, 30],
             user_id_2: ["1", "2"],
             winner: "1"
           }
         ]}
      end do
      {:ok, win_rates} = Battle.Service.WebService.RankList.get_battle_info()

      calculate_winrate = [
        %{user_id: "1", rate: 1.0, ai_name: "hahaha"},
        %{user_id: "123", rate: 0.5, ai_name: "Biu biu biu~~!!"},
        %{user_id: "2", rate: 0.0, ai_name: "wawawawa"},
        %{user_id: "456", rate: 0.5, ai_name: "Biu"}
      ]
      UserAi.clean_message("1")
      UserAi.clean_message("123")
      UserAi.clean_message("2")
      UserAi.clean_message("456")

      assert calculate_winrate == win_rates
    end
  end

  test "calculate win rate failure" do
    # 模拟函数返回一个正确的列表
    with_mock Battle.Mongo.BattleResult, [:passthrough],
              get_battle_results_within_24_hour: fn ->
                {:error,"not found"}
              end
      do
      {:error, reason} = Battle.Service.WebService.RankList.get_battle_info()

      assert reason == []
    end
  end


  test "insert win rate" do
    User.save_user("1","123123","liuliuliu")
    User.save_user("123","321321","liuliuliu")
    User.save_user("456","131313","liuliuliu")
    User.save_user("2","121212","liuliuliu")

    calculate_win_rate = [
      %{user_id: "1", rate: 1.0, ai_name: "hahaha", avatar: nil},
      %{user_id: "123", rate: 0.5, ai_name: "Biu biu biu~~!!", avatar: nil},
      %{user_id: "456", rate: 0.5, ai_name: "Biu", avatar: nil},
      %{user_id: "2", rate: 0.0, ai_name: "wawawawa", avatar: nil}
    ]

    Battle.Service.WebService.RankList.insert_win_rate(calculate_win_rate)
    {:ok, detail} = Battle.Mongo.RankList.get_rank_list(0, 4)
    Enum.map(detail,fn message -> Battle.Mongo.RankList.remove_rank(message.user_id) end)

    User.remove_user("1")
    User.remove_user("123")
    User.remove_user("456")
    User.remove_user("2")

    assert detail == calculate_win_rate
  end
end

