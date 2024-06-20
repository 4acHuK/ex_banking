defmodule ExBanking.CurrenciesHandler do
  use GenServer

  def start_link(params) when is_list(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def init(value) do
    {:ok, value}
  end

  def create_currency(currency) do
    GenServer.cast(__MODULE__, {:create_currency, currency})
  end

  def handle_cast({:create_currency, currency}, currencies) do
    if currency_exists?(currency, currencies) do
      {:noreply, currencies}
    else
      {:noreply, [currency | currencies]}
    end
  end

  defp currency_exists?(target_currency, currencies) do
    Enum.any?(currencies, &(&1 == target_currency))
  end
end
