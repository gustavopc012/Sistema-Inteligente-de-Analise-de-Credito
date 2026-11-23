defmodule CreditEngine.Web.PropostasHTTPTest do
  # async: false porque usa o armazenamento da aplicação e o Circuit Breaker.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias CreditEngine.ProposalStore
  alias CreditEngine.Web.JSONDecoder

  setup do
    {:ok, servidor} = CreditEngine.Web.start(0)
    on_exit(fn -> CreditEngine.Web.stop(servidor.pid) end)
    {:ok, porta: servidor.porta}
  end

  # Requisição pelo socket, como em web_test.exs. Devolve o código e o JSON.
  defp req(porta, metodo, alvo, corpo \\ "") do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, porta, [:binary, active: false], 5_000)

    :ok =
      :gen_tcp.send(socket, [
        "#{metodo} #{alvo} HTTP/1.1\r\nHost: 127.0.0.1\r\n",
        "Content-Type: application/json\r\nContent-Length: #{byte_size(corpo)}\r\n",
        "Connection: close\r\n\r\n",
        corpo
      ])

    resposta = receber(socket, "")
    :gen_tcp.close(socket)

    [cabecalho, corpo_resposta] = String.split(resposta, "\r\n\r\n", parts: 2)
    [_versao, codigo | _] = cabecalho |> String.split("\r\n") |> hd() |> String.split(" ")
    {:ok, json} = JSONDecoder.decode(corpo_resposta)
    {String.to_integer(codigo), json}
  end

  defp receber(socket, acumulado) do
    case :gen_tcp.recv(socket, 0, 5_000) do
      {:ok, dados} -> receber(socket, acumulado <> dados)
      {:error, :closed} -> acumulado
    end
  end

  defp novo_id, do: "HTTP #{System.unique_integer([:positive])}"

  # Perfil de mau pagador do plan.md, com mercado normal e comportamento padrão.
  defp corpo(id) do
    ~s({"id": "#{id}",
        "macroeconomic_data": {"taxa_inadimplencia_mercado": 0.05},
        "behavioral_data": {"transacoes_noturnas": 2, "dispositivos_novos": 0, "tentativas_login_falhas": 1},
        "open_finance_data": {"comprometimento_renda": 0.8, "atrasos_12m": 3},
        "applicant_data": {"tempo_relacionamento_anos": 1}})
  end

  defp caminho(id), do: "/api/propostas/" <> URI.encode(id, &URI.char_unreserved?/1)

  test "fluxo completo: cadastrar, consultar, listar, analisar duas vezes e ver o histórico",
       %{porta: p} do
    id = novo_id()

    assert {201, %{"ok" => true, "proposta" => %{"id" => ^id, "status" => "nao_analisada"}}} =
             req(p, "POST", "/api/propostas", corpo(id))

    assert {200, %{"proposta" => proposta}} = req(p, "GET", caminho(id))
    assert proposta["open_finance_data"] == %{"comprometimento_renda" => 0.8, "atrasos_12m" => 3}

    assert {200, %{"historico" => []}} = req(p, "GET", caminho(id) <> "/historico")

    assert {200, %{"analise" => %{"status" => "recusado", "score" => score}}} =
             req(p, "POST", caminho(id) <> "/analisar")

    assert score > 0.6

    assert {200, %{"analise" => %{"status" => "recusado"}}} =
             req(p, "POST", caminho(id) <> "/analisar")

    assert {200, %{"historico" => [primeira, segunda]}} =
             req(p, "GET", caminho(id) <> "/historico")

    assert primeira["proposta_id"] == id and segunda["proposta_id"] == id
    assert primeira["analisada_em"] <= segunda["analisada_em"]

    assert {200, %{"propostas" => lista}} = req(p, "GET", "/api/propostas")
    assert %{"id" => id, "status" => "recusado"} in lista
  end

  test "identificador duplicado devolve 409", %{porta: p} do
    id = novo_id()
    {201, _} = req(p, "POST", "/api/propostas", corpo(id))

    assert {409, %{"ok" => false}} = req(p, "POST", "/api/propostas", corpo(id))
  end

  test "dados inválidos e JSON malformado devolvem 422", %{porta: p} do
    assert {422, %{"erro" => %{"campo" => "id"}}} =
             req(p, "POST", "/api/propostas", ~s({"id": ""}))

    assert {422, %{"ok" => false}} = req(p, "POST", "/api/propostas", ~s({"id": "X", "outro": 1}))
    assert {422, %{"ok" => false}} = req(p, "POST", "/api/propostas", "{x")
    assert {422, %{"ok" => false}} = req(p, "POST", "/api/propostas", "[1, 2]")
  end

  test "proposta inexistente devolve 404 em todas as rotas", %{porta: p} do
    assert {404, _} = req(p, "GET", "/api/propostas/NAO-EXISTE")
    assert {404, _} = req(p, "GET", "/api/propostas/NAO-EXISTE/historico")
    assert {404, _} = req(p, "POST", "/api/propostas/NAO-EXISTE/analisar")
  end

  test "análise sem decisão devolve 422 e não altera o histórico", %{porta: p} do
    id = novo_id()
    {201, _} = req(p, "POST", "/api/propostas", ~s({"id": "#{id}"}))

    assert {422, %{"erro" => %{"campo" => "taxa_inadimplencia_mercado"}}} =
             req(p, "POST", caminho(id) <> "/analisar")

    assert {200, %{"historico" => []}} = req(p, "GET", caminho(id) <> "/historico")
  end

  test "rotas e métodos desconhecidos devolvem 404 e 405", %{porta: p} do
    assert {405, _} = req(p, "DELETE", "/api/propostas")
    assert {405, _} = req(p, "GET", "/api/propostas/X/analisar")
    assert {404, _} = req(p, "GET", "/api/propostas/X/outra")
    assert {404, _} = req(p, "GET", "/api/propostasX")
  end

  test "as rotas anteriores continuam funcionando", %{porta: p} do
    assert {200, %{"circuit_breaker" => _}} = req(p, "GET", "/api/status")
    assert {422, %{"ok" => false}} = req(p, "GET", "/api/analisar?id=")
  end

  test "armazenamento parado devolve 500 com mensagem genérica", %{porta: p} do
    :ok = Supervisor.terminate_child(CreditEngine.Supervisor, ProposalStore)
    on_exit(fn -> Supervisor.restart_child(CreditEngine.Supervisor, ProposalStore) end)

    log =
      capture_log(fn ->
        assert {500, %{"erro" => %{"mensagem" => mensagem}}} = req(p, "GET", "/api/propostas")
        refute mensagem =~ "ProposalStore"
        assert {500, _} = req(p, "POST", "/api/propostas", corpo(novo_id()))
      end)

    assert log =~ "indisponível"
  end
end
