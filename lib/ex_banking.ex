defmodule ExBanking do
  use GenServer
  alias ExBanking.UserManager
  alias ExBanking.OperationCounter

  @max_operations 10

  def start_link(_) do
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
    case UserManager.create_user(user) do
      :ok -> {:reply, :ok, state}
      {:error, :user_already_exists} -> {:reply, {:error, :user_already_exists}, state}
    end
  end

  def handle_call({:deposit, user, amount, currency}, _from, state) do
    if can_process_operation?(user) do
      OperationCounter.increment(user)
      case UserManager.deposit(user, amount, currency) do
        {:ok, balance} ->
          OperationCounter.decrement(user)
          {:reply, {:ok, balance}, state}
        {:error, reason} ->
          OperationCounter.decrement(user)
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :too_many_requests_to_user}, state}
    end
  end

  def handle_call({:withdraw, user, amount, currency}, _from, state) do
    if can_process_operation?(user) do
      OperationCounter.increment(user)
      case UserManager.withdraw(user, amount, currency) do
        {:ok, balance} ->
          OperationCounter.decrement(user)
          {:reply, {:ok, balance}, state}
        {:error, reason} ->
          OperationCounter.decrement(user)
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :too_many_requests_to_user}, state}
    end
  end

  def handle_call({:get_balance, user, currency}, _from, state) do
    case UserManager.get_balance(user, currency) do
      {:ok, balance} -> {:reply, {:ok, balance}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:send, from_user, to_user, amount, currency}, _from, state) do
    if can_process_operation?(from_user) and can_process_operation?(to_user) do
      OperationCounter.increment(from_user)
      OperationCounter.increment(to_user)
      case UserManager.send(from_user, to_user, amount, currency) do
        {:ok, from_balance, to_balance} ->
          OperationCounter.decrement(from_user)
          OperationCounter.decrement(to_user)
          {:reply, {:ok, from_balance, to_balance}, state}
        {:error, reason} ->
          OperationCounter.decrement(from_user)
          OperationCounter.decrement(to_user)
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :too_many_requests_to_user}, state}
    end
  end

  defp can_process_operation?(user) do
    OperationCounter.get_count(user) < @max_operations
  end
end
