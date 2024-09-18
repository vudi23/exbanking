defmodule ExBankingTest do
  use ExUnit.Case, async: true

  import ExBanking

  setup do
    Application.stop(:ex_banking)
    Application.start(:ex_banking)
  end

  describe "create_user" do
    test "can create user" do
      assert create_user("valid_user_name") == :ok
    end

    test "returns error with invalid user name format" do
      assert create_user(123) == {:error, :wrong_arguments}
    end

    test "returns error when already registered" do
      create_user("same_user_name")
      assert create_user("same_user_name") == {:error, :user_already_exists}
    end
  end

  describe "deposit" do
    test "created user can deposit currency" do
      create_user("user")
      assert deposit("user", 100, "usd") == {:ok, 100}
    end

    test "nonexisting user can't deposit curency" do
      assert deposit("nonexisting_user", 100, "usd") == {:error, :user_does_not_exist}
    end

    test "can't deposit with invalid currency input" do
      create_user("user")
      assert deposit("user", 100, 100) == {:error, :wrong_arguments}
      assert deposit("user", "usd", "usd") == {:error, :wrong_arguments}
    end

    test "depositing adds to existing currency amount" do
      create_user("user")
      assert deposit("user", 100, "usd") == {:ok, 100}
      assert deposit("user", 100.50, "usd") == {:ok, 200.5}
    end

    test "depositing is case sensitive to currency" do
      create_user("user")
      assert deposit("user", 100, "usd") == {:ok, 100}
      assert deposit("user", 100, "USD") == {:ok, 100}
    end

    test "truncates amount input after two digits" do
      create_user("user")
      assert deposit("user", 100.1111, "usd") == {:ok, 100.11}
      assert deposit("user", 100.9999, "eur") == {:ok, 100.99}
    end

    test "can't deposit nothing" do
      create_user("user")
      assert deposit("user", 0, "usd") == {:error, :wrong_arguments}
    end
  end

  describe "withdraw" do
    test "can withdraw currency if existing in adequate amount" do
      create_user("user")
      deposit("user", 100, "usd")
      assert withdraw("user", 40, "usd") == {:ok, 60}
      assert withdraw("user", 25, "usd") == {:ok, 35}
    end

    test "can't withdraw currency if not existing in adequate amount" do
      create_user("user")
      deposit("user", 100, "usd")
      assert withdraw("user", 575, "usd") == {:error, :not_enough_money}
    end

    test "can't withdraw currency if currency not existing" do
      create_user("user")
      deposit("user", 100, "usd")
      assert withdraw("user", 75, "eur") == {:error, :not_enough_money}
    end

    test "can't withdraw if user doesn't exist" do
      assert withdraw("non_existing_user", 50, "usd") == {:error, :user_does_not_exist}
    end

    test "can't withdraw if arguments wrong" do
      create_user("user")
      deposit("user", 100, "usd")
      assert withdraw("user", 75, 75) == {:error, :wrong_arguments}
      assert withdraw("user", "usd", "usd") == {:error, :wrong_arguments}
    end

    test "can withdraw nothing" do
      create_user("user")
      deposit("user", 100, "usd")
      assert withdraw("user", 0, "usd") == {:error, :wrong_arguments}
    end
  end

  describe "get_balance" do
    test "created user can check balance" do
      create_user("user")
      deposit("user", 100.47, "usd")
      assert get_balance("user", "usd") == {:ok, 100.47}
    end

    test "nonexisting user can't check balance" do
      assert get_balance("non_existing_user", "usd") == {:error, :user_does_not_exist}
    end

    test "returns error for wrong arguments" do
      create_user("user")
      deposit("user", 100.47, "usd")
      assert get_balance("user", 125) == {:error, :wrong_arguments}
    end

    test "returns zero for currencies not in portfolio" do
      create_user("user")
      deposit("user", 100.47, "usd")
      assert get_balance("user", "eur") == {:ok, 0}
    end
  end

  describe "send" do
    test "can send money with sufficient funds" do
      create_user("user1")
      create_user("user2")
      deposit("user1", 100, "usd")
      deposit("user2", 100, "usd")

      assert send("user2", "user1", 50, "usd") == {:ok, 50, 150}
      assert get_balance("user1", "usd") == {:ok, 150}
      assert get_balance("user2", "usd") == {:ok, 50}
    end

    test "can't send money with insufficient funds" do
      create_user("user1")
      create_user("user2")
      deposit("user1", 150, "usd")
      deposit("user2", 50, "usd")

      assert send("user2", "user1", 100, "usd") == {:error, :not_enough_money}

      assert get_balance("user1", "usd") == {:ok, 150}
      assert get_balance("user2", "usd") == {:ok, 50}
    end

    test "can't send to user that doesn't exist" do
      create_user("user")
      deposit("user", 100, "usd")

      assert send("user", "non_existing_receiver", 50, "usd") ==
               {:error, :receiver_does_not_exist}

      assert get_balance("user", "usd") == {:ok, 100}
    end

    test "can't send from user that doesn't exist" do
      create_user("user")
      deposit("user", 100, "usd")

      assert send("non_existing_sender", "user", 50, "usd") ==
               {:error, :sender_does_not_exist}

      assert get_balance("user", "usd") == {:ok, 100}
    end
  end
end
