defmodule CreditEngine.Web do
  @moduledoc """
  Interface web de demonstração do MVP.

  Usa o servidor HTTP que já vem com o Erlang/OTP (`:httpd`, da aplicação
  `:inets`), sem dependências externas. O servidor só aceita conexões do
  próprio computador (`127.0.0.1`).

  Para abrir: `mix credit_engine.web`, ou `CreditEngine.Web.start()` dentro do
  `iex -S mix`. Depois, acesse http://localhost:4000 no navegador.
  """

  @porta_padrao 4000

  @doc """
  Inicia o servidor. Use a porta `0` para escolher uma porta livre.
  Devolve `{:ok, %{pid: pid, porta: porta, url: url}}`.
  """
  @spec start(non_neg_integer()) :: {:ok, map()} | {:error, term()}
  def start(porta \\ @porta_padrao) do
    {:ok, _} = Application.ensure_all_started(:inets)
    raiz = Application.app_dir(:credit_engine, "priv/static") |> String.to_charlist()

    configuracao = [
      port: porta,
      bind_address: {127, 0, 0, 1},
      server_name: ~c"credit_engine",
      server_root: raiz,
      document_root: raiz,
      modules: [CreditEngine.Web.Handler]
    ]

    with {:ok, pid} <- :inets.start(:httpd, configuracao) do
      porta = :httpd.info(pid)[:port]
      {:ok, %{pid: pid, porta: porta, url: "http://localhost:#{porta}"}}
    end
  end

  @doc "Para o servidor iniciado por `start/1`."
  @spec stop(pid()) :: :ok | {:error, term()}
  def stop(pid), do: :inets.stop(:httpd, pid)
end
