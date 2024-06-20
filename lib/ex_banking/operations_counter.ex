defmodule ExBanking.OperationCounter do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def increment(user) do
    Agent.update(__MODULE__, fn state ->
      Map.update(state, user, 1, fn count -> count + 1 end)
    end)
  end

  def decrement(user) do
    Agent.update(__MODULE__, fn state ->
      Map.update(state, user, 0, fn count -> count - 1 end)
    end)
  end

  def get_count(user) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, user, 0)
    end)
  end
end
