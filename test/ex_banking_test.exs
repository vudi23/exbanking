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
end
