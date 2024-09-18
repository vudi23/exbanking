defmodule ExBanking do
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with :ok <- valid_string_input(user),
         :ok <- insert_new_user(user),
         do: :ok
  end

  defp valid_string_input(param) do
    if is_binary(param), do: :ok, else: {:error, :wrong_arguments}
  end

  defp insert_new_user(user) do
    with {:error, :already_exists} <- ConCache.insert_new(:bank, user, %{}),
         do: {:error, :user_already_exists}
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
