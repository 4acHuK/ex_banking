defmodule ExBanking.UserManager do
  use GenServer
  alias ExBanking.CurrenciesHandler

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_params) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def create_user(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  def deposit(user, amount, currency) do
    GenServer.call(__MODULE__, {:deposit, user, amount, currency})
  end

  def withdraw(user, amount, currency) do
    GenServer.call(__MODULE__, {:withdraw, user, amount, currency})
  end

  def get_balance(user, currency) do
    GenServer.call(__MODULE__, {:get_balance, user, currency})
  end

  def send(from_user, to_user, amount, currency) do
    GenServer.call(__MODULE__, {:send, from_user, to_user, amount, currency})
  end

  def handle_call({:create_user, user}, _from, state) do
    if Map.has_key?(state, user) do
      {:reply, {:error, :user_already_exists}, state}
    else
      new_state = Map.put(state, user, %{})
      {:reply, :ok, new_state}
    end
  end

  def handle_call({:deposit, user, amount, currency}, _from, state) do
    case Map.get(state, user) do
      nil -> {:reply, {:error, :user_does_not_exist}, state}
      balances ->
        new_balance = round_amount(Map.get(balances, currency, 0) + amount)
        new_state = Map.put(state, user, Map.put(balances, currency, new_balance))
        {:reply, {:ok = CurrenciesHandler.create_currency(currency), new_balance}, new_state}

    end
  end

  def handle_call({:withdraw, user, amount, currency}, _from, state) do
    case Map.get(state, user) do
      nil -> {:reply, {:error, :user_does_not_exist}, state}
      balances ->
        current_balance = Map.get(balances, currency, 0)
        if current_balance < amount do
          {:reply, {:error, :not_enough_money}, state}
        else
          new_balance = round_amount(current_balance - amount)
          new_state = Map.put(state, user, Map.put(balances, currency, new_balance))
          {:reply, {:ok, new_balance}, new_state}
        end
    end
  end

  def handle_call({:get_balance, user, currency}, _from, state) do
    case Map.get(state, user) do
      nil -> {:reply, {:error, :user_does_not_exist}, state}
      balances ->
        balance = Map.get(balances, currency, 0)
        {:reply, {:ok, balance}, state}
    end
  end

  def handle_call({:send, from_user, to_user, amount, currency}, _from, state) do
    from_balances = Map.get(state, from_user)
    to_balances = Map.get(state, to_user)

    cond do
      from_balances == nil -> {:reply, {:error, :sender_does_not_exist}, state}
      to_balances == nil -> {:reply, {:error, :receiver_does_not_exist}, state}
      Map.get(from_balances, currency, 0) < amount -> {:reply, {:error, :not_enough_money}, state}
      true ->
        from_new_balance = round_amount(Map.get(from_balances, currency, 0) - amount)
        to_new_balance = round_amount(Map.get(to_balances, currency, 0) + amount)
        new_state = state
                    |> Map.put(from_user, Map.put(from_balances, currency, from_new_balance))
                    |> Map.put(to_user, Map.put(to_balances, currency, to_new_balance))
        {:reply, {:ok, from_new_balance, to_new_balance}, new_state}
    end
  end

  defp round_amount(amount) do
    Float.round(amount * 1.0, 2)
  end
end
