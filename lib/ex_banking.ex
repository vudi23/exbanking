defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ExBanking.hello()
      :world

  """
  def hello do
    :world
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
