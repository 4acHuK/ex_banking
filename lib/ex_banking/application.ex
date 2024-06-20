defmodule ExBanking.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.CounterNames},
      ExBanking.UserManager,
      ExBanking.OperationCounter,
      ExBanking.CurrenciesHandler,
      ExBanking
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
