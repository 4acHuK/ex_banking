defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "creating a new user" do
    assert ExBanking.create_user("Anatolii") == :ok
    assert ExBanking.create_user("Anatolii") == {:error, :user_already_exists}
  end

  test "depositing money" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 100, "USD") == {:ok, 100.00}  # Integer rounding test
    assert ExBanking.deposit("Bob", 50.123, "USD") == {:ok, 150.12}
    assert ExBanking.deposit("Bob", 0.005, "USD") == {:ok, 150.13}  # Rounding test
  end

  test "withdrawing money" do
    ExBanking.create_user("Anna")
    ExBanking.deposit("Anna", 100.0, "USD")
    assert ExBanking.withdraw("Anna", 40, "USD") == {:ok, 60.00}  # Integer rounding test
    assert ExBanking.withdraw("Anna", 0.005, "USD") == {:ok, 59.99}  # Rounding test
    assert ExBanking.withdraw("Anna", 100.0, "USD") == {:error, :not_enough_money}
  end

  test "getting balance" do
    ExBanking.create_user("Dave")
    ExBanking.deposit("Dave", 200.0, "USD")
    assert ExBanking.get_balance("Dave", "USD") == {:ok, 200.0}
  end

  test "sending money" do
    ExBanking.create_user("Eve")
    ExBanking.create_user("Frank")
    ExBanking.deposit("Eve", 300.0, "USD")
    assert ExBanking.send("Eve", "Frank", 50, "USD") == {:ok, 250.00, 50.00}  # Integer rounding test
    assert ExBanking.send("Eve", "Frank", 50.12, "USD") == {:ok, 199.88, 100.12}
    assert ExBanking.send("Eve", "Frank", 0.125, "USD") == {:ok, 199.75, 100.25}  # Rounding test
  end

  test "handling multiple calls" do
    ExBanking.create_user("Alice")
    ExBanking.create_user("Jack")
    for _i <- 1..10 do
      ExBanking.OperationCounter.increment("Alice")
    end
    for _i <- 1..5 do
      ExBanking.OperationCounter.increment("Jack")
    end

    assert ExBanking.deposit("Alice", 1000.0, "USD") == {:error, :too_many_requests_to_user}
    assert ExBanking.deposit("Jack", 1000.0, "USD") == {:ok, 1000.0}
  end

  # test "handling multiple users concurrently" do
  #   ExBanking.create_user("Alice")
  #   ExBanking.create_user("Bob")

  #   # Spawn tasks for Alice
  #   alice_tasks = for i <- 1..10 do
  #     Task.async(fn -> ExBanking.deposit("Alice", i*1.0, "USD") end)
  #   end

  #   # Spawn tasks for Bob
  #   bob_tasks = for i <- 1..10 do
  #     Task.async(fn -> ExBanking.deposit("Bob", i*1.0, "USD") end)
  #   end

  #   # Combine all tasks
  #   all_tasks = alice_tasks ++ bob_tasks
  #   IO.inspect(all_tasks, label: 'all tasks')

  #   # Wait for all tasks to complete
  #   Task.await_many(all_tasks, 20000)

  #   # Make assertions after all tasks have completed
  #   assert ExBanking.deposit("Alice", 1000.0, "USD") == {:error, :too_many_requests_to_user}
  #   assert ExBanking.deposit("Bob", 1000.0, "USD") == {:error, :too_many_requests_to_user}

  #   # Ensure the next request passes after previous ones have finished
  #   assert ExBanking.deposit("Alice", 1.0, "USD") == {:ok, 11.0}
  #   assert ExBanking.deposit("Bob", 1.0, "USD") == {:ok, 11.0}
  # end

end
