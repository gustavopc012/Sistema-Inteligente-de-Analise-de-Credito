defmodule Mix.Tasks.CreditEngine.Web do
  @shortdoc "Abre a interface web de demonstração em http://localhost:4000"

  @moduledoc """
  Inicia a aplicação e a interface web de demonstração.

      mix credit_engine.web          # porta 4000
      mix credit_engine.web 4001     # outra porta

  Para encerrar, use Ctrl+C duas vezes.
  """

  use Mix.Task

  @impl true
  def run(argumentos) do
    porta =
      case argumentos do
        [porta | _] -> String.to_integer(porta)
        [] -> 4000
      end

    Mix.Task.run("app.start")

    case CreditEngine.Web.start(porta) do
      {:ok, %{url: url}} ->
        Mix.shell().info("Interface web em #{url} (Ctrl+C duas vezes para encerrar)")
        Process.sleep(:infinity)

      {:error, motivo} ->
        Mix.raise("Não foi possível iniciar a interface web: #{inspect(motivo)}")
    end
  end
end
