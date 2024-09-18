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
         :ok <- valid_number_input(amount),
         :ok <- deposit_money(user, currency, amount),
         do: {:ok, fetch_currency_balance(user, currency)}
  end

  defp valid_number_input(param) do
    if is_number(param) and param > 0, do: :ok, else: {:error, :wrong_arguments}
  end

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
