defmodule CreditEngine.Web.Handler do
  @moduledoc """
  Rotas da interface web, como módulo de callback do `:httpd` (Erlang/OTP).

  - `GET /`: página da interface (`priv/static/index.html`).
  - `GET /api/analisar?...`: analisa a proposta descrita na query.
  - `GET /api/status`: estado do Circuit Breaker e parâmetros.

  Cadastro e histórico de propostas (incremento 11), com corpo em JSON:

  - `POST /api/propostas`: cadastra uma proposta.
  - `GET /api/propostas`: lista identificador e estado atual.
  - `GET /api/propostas/:id`: consulta uma proposta.
  - `GET /api/propostas/:id/historico`: histórico de análises.
  - `POST /api/propostas/:id/analisar`: analisa a proposta cadastrada.
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

    corpo_requisicao = mod(dados, :entity_body) |> :erlang.list_to_binary()

    {codigo, tipo, corpo} = rota(metodo, caminho, query, corpo_requisicao)

    cabecalho = [
      code: codigo,
      content_type: String.to_charlist(tipo),
      content_length: Integer.to_charlist(byte_size(corpo)),
      cache_control: ~c"no-store"
    ]

    {:proceed, [{:response, {:response, cabecalho, [corpo]}}]}
  end

  @doc false
  def rota(metodo, caminho, query, corpo \\ "")

  def rota("GET", caminho, _query, _corpo) when caminho in ["/", "/index.html"] do
    {200, "text/html; charset=utf-8", File.read!(pagina())}
  end

  def rota("GET", "/api/analisar", query, _corpo),
    do: json(API.analisar(URI.decode_query(query)))

  def rota("GET", "/api/status", _query, _corpo), do: json(API.status())

  def rota(metodo, "/api/propostas" <> resto, _query, corpo) do
    case {metodo, segmentos(resto)} do
      {"POST", []} -> json(API.cadastrar_proposta(corpo))
      {"GET", []} -> json(API.listar_propostas())
      {"GET", [id]} -> json(API.consultar_proposta(id))
      {"GET", [id, "historico"]} -> json(API.historico_proposta(id))
      {"POST", [id, "analisar"]} -> json(API.analisar_proposta(id))
      {_metodo, []} -> nao_permitido()
      {_metodo, [_id]} -> nao_permitido()
      {_metodo, [_id, acao]} when acao in ["historico", "analisar"] -> nao_permitido()
      _ -> nao_encontrada()
    end
  end

  def rota("GET", _caminho, _query, _corpo), do: nao_encontrada()

  def rota(_metodo, _caminho, _query, _corpo), do: nao_permitido()

  defp nao_encontrada, do: json({404, %{ok: false, erro: "Rota não encontrada."}})
  defp nao_permitido, do: json({405, %{ok: false, erro: "Método não permitido."}})

  # "" -> [], "/abc" -> ["abc"], "/abc/historico" -> ["abc", "historico"].
  # O identificador pode vir codificado na URL (por exemplo, com espaço).
  defp segmentos(""), do: []
  defp segmentos("/"), do: []

  defp segmentos("/" <> resto) do
    partes = resto |> String.trim_trailing("/") |> String.split("/")
    if "" in partes, do: :invalido, else: Enum.map(partes, &URI.decode/1)
  end

  defp segmentos(_resto), do: :invalido

  defp json({codigo, corpo}), do: {codigo, "application/json; charset=utf-8", JSON.encode(corpo)}

  defp dividir(uri) do
    case String.split(uri, "?", parts: 2) do
      [caminho, query] -> {caminho, query}
      [caminho] -> {caminho, ""}
    end
  end

  defp pagina, do: Application.app_dir(:credit_engine, "priv/static/index.html")
end
