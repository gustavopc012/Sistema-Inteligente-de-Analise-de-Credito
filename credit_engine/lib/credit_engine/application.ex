defmodule CreditEngine.Application do
  @moduledoc "Aplicação OTP do CreditEngine."
  use Application

  @impl true
  def start(_type, _args) do
    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: CreditEngine.Supervisor)
  end
end
