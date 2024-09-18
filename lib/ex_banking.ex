defmodule ExBanking do
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with :ok <- valid_string_input(user),
         :ok <- insert_new_user(user),
         do: :ok
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    with :ok <- valid_string_input(currency),
         {:ok, amount} <- normalize_number_input(amount),
         :ok <- deposit_money(user, currency, amount),
         do: {:ok, fetch_currency_balance(user, currency)}
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    with :ok <- valid_string_input(currency),
         {:ok, amount} <- normalize_number_input(amount),
         :ok <- withdraw_money(user, currency, amount),
         do: {:ok, fetch_currency_balance(user, currency)}
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    with :ok <- valid_string_input(currency),
         portfolio = ConCache.get(:bank, user) do
      case portfolio do
        nil -> {:error, :user_does_not_exist}
        _ -> {:ok, Map.get(portfolio, currency, 0)}
      end
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    with {:ok, old_balance_sender} <- check_sender_funds(from_user, currency),
         {:ok, _old_balance_reciever} <- check_reciever_funds(to_user, currency),
         :ok <- check_enough_money_to_transfer(old_balance_sender, amount),
         {:ok, new_balance_sender} <- withdraw(from_user, amount, currency),
         {:ok, new_balance_receiver} <- deposit(to_user, amount, currency),
         do: {:ok, new_balance_sender, new_balance_receiver}
  end

  defp check_sender_funds(user, currency) do
    with {:error, :user_does_not_exist} <- get_balance(user, currency),
         do: {:error, :sender_does_not_exist}
  end

  defp check_reciever_funds(user, currency) do
    with {:error, :user_does_not_exist} <- get_balance(user, currency),
         do: {:error, :receiver_does_not_exist}
  end

  defp check_enough_money_to_transfer(current_amount, desired_amount) do
    if desired_amount <= current_amount, do: :ok, else: {:error, :not_enough_money}
  end

  defp normalize_number_input(param) when is_float(param) and param > 0,
    do: {:ok, Decimal.from_float(param) |> Decimal.round(2, :down) |> Decimal.to_float()}

  defp normalize_number_input(param) when is_integer(param) and param > 0,
    do: {:ok, Decimal.round(param, 2, :down) |> Decimal.to_float()}

  defp normalize_number_input(_), do: {:error, :wrong_arguments}

  defp valid_string_input(param) do
    if is_binary(param), do: :ok, else: {:error, :wrong_arguments}
  end

  defp insert_new_user(user) do
    with {:error, :already_exists} <- ConCache.insert_new(:bank, user, %{}),
         do: {:error, :user_already_exists}
  end

  defp deposit_money(user, currency, amount) do
    with {:error, :not_existing} <-
           ConCache.update_existing(:bank, user, fn currency_map ->
             {:ok, Map.update(currency_map, currency, amount, fn balance -> balance + amount end)}
           end),
         do: {:error, :user_does_not_exist}
  end

  defp withdraw_money(user, currency, amount) do
    with {:error, :not_existing} <-
           ConCache.update_existing(:bank, user, fn currency_map ->
             updated_map =
               Map.update(currency_map, currency, 0, fn balance -> balance - amount end)

             if Map.get(updated_map, currency) >= 0 and Map.has_key?(currency_map, currency),
               do: {:ok, updated_map},
               else: {:error, :not_enough_money}
           end),
         do: {:error, :user_does_not_exist}
  end

  defp fetch_currency_balance(user, currency) do
    Map.get(ConCache.get(:bank, user), currency)
  end

  def start_link do
    Supervisor.start_link(
      [
        {ConCache, [name: :bank, ttl_check_interval: false]}
      ],
      strategy: :one_for_one,
      name: __MODULE__
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, []}
    }
  end
end
