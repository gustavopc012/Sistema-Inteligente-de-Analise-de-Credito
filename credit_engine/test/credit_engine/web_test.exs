defmodule CreditEngine.WebTest do
  # async: false porque a análise passa pelo Circuit Breaker, que tem contador global.
  use ExUnit.Case, async: false

  setup do
    # Porta 0: o sistema escolhe uma porta livre.
    {:ok, servidor} = CreditEngine.Web.start(0)
    on_exit(fn -> CreditEngine.Web.stop(servidor.pid) end)
    {:ok, url: servidor.url, pid: servidor.pid}
  end

  defp get(url) do
    {:ok, {{_versao, codigo, _frase}, cabecalhos, corpo}} =
      :httpc.request(:get, {String.to_charlist(url), []}, [], body_format: :binary)

    tipo = cabecalhos |> List.keyfind(~c"content-type", 0) |> elem(1) |> to_string()
    {codigo, tipo, corpo}
  end

  test "GET / devolve a página da interface", %{url: url} do
    assert {200, "text/html" <> _, corpo} = get(url <> "/")
    assert corpo =~ "Sistema Inteligente de Análise de Crédito"
  end

  test "GET /api/analisar devolve a decisão em JSON", %{url: url} do
    query =
      URI.encode_query(%{
        "id" => "PROP-HTTP",
        "taxa_inadimplencia_mercado" => "0.05",
        "transacoes_noturnas" => "2",
        "dispositivos_novos" => "0",
        "tentativas_login_falhas" => "1",
        "comprometimento_renda" => "0.8",
        "atrasos_12m" => "3",
        "tempo_relacionamento_anos" => "1"
      })

    assert {200, "application/json" <> _, corpo} = get(url <> "/api/analisar?" <> query)
    assert corpo =~ ~s("ok":true)
    assert corpo =~ ~s("status":"recusado")
  end

  test "GET /api/analisar com entrada inválida devolve 422", %{url: url} do
    assert {422, "application/json" <> _, corpo} = get(url <> "/api/analisar?id=")
    assert corpo =~ ~s("ok":false)
  end

  test "GET /api/status devolve o Circuit Breaker e os parâmetros", %{url: url} do
    assert {200, "application/json" <> _, corpo} = get(url <> "/api/status")
    assert corpo =~ ~s("circuit_breaker":)
    assert corpo =~ ~s("limite_taxa_inadimplencia":)
  end

  test "rota desconhecida devolve 404", %{url: url} do
    assert {404, _tipo, _corpo} = get(url <> "/nada")
  end

  test "o servidor só aceita conexões do próprio computador", %{pid: pid} do
    assert :httpd.info(pid)[:bind_address] == {127, 0, 0, 1}
  end
end
