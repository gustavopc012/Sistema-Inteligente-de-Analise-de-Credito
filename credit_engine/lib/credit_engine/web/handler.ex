defmodule CreditEngine.Web.Handler do
  @moduledoc """
  Rotas da interface web, como módulo de callback do `:httpd` (Erlang/OTP).

  - `GET /`: página da interface (`priv/static/index.html`).
  - `GET /api/analisar?...`: analisa a proposta descrita na query.
  - `GET /api/status`: estado do Circuit Breaker e parâmetros.
  """

  require Record

  alias CreditEngine.Web.{API, JSON}

  Record.defrecordp(:mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl"))

  # O :httpd chama a função do/1 do módulo. Como `do` é palavra reservada
  # em Elixir, o nome é definido com unquote.
  @doc false
  def unquote(:do)(dados) do
    metodo = mod(dados, :method) |> to_string()
    {caminho, query} = dividir(mod(dados, :request_uri) |> to_string())

    {codigo, tipo, corpo} = rota(metodo, caminho, query)

    cabecalho = [
      code: codigo,
      content_type: String.to_charlist(tipo),
      content_length: Integer.to_charlist(byte_size(corpo)),
      cache_control: ~c"no-store"
    ]

    {:proceed, [{:response, {:response, cabecalho, [corpo]}}]}
  end

  @doc false
  def rota("GET", caminho, _query) when caminho in ["/", "/index.html"] do
    {200, "text/html; charset=utf-8", File.read!(pagina())}
  end

  def rota("GET", "/api/analisar", query), do: json(API.analisar(URI.decode_query(query)))
  def rota("GET", "/api/status", _query), do: json(API.status())
  def rota("GET", _caminho, _query), do: json({404, %{ok: false, erro: "Rota não encontrada."}})
  def rota(_metodo, _caminho, _query), do: json({405, %{ok: false, erro: "Use GET."}})

  defp json({codigo, corpo}), do: {codigo, "application/json; charset=utf-8", JSON.encode(corpo)}

  defp dividir(uri) do
    case String.split(uri, "?", parts: 2) do
      [caminho, query] -> {caminho, query}
      [caminho] -> {caminho, ""}
    end
  end

  defp pagina, do: Application.app_dir(:credit_engine, "priv/static/index.html")
end
