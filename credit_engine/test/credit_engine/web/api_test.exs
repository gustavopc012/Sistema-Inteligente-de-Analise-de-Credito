defmodule CreditEngine.Web.APITest do
  # async: false porque a análise passa pelo Circuit Breaker, que tem contador global.
  use ExUnit.Case, async: false

  alias CreditEngine.Web.API

  # Parâmetros do formulário, em texto, como chegam do navegador.
  defp parametros(alteracoes \\ %{}) do
    centro = Application.fetch_env!(:credit_engine, :anomalias)[:centro]
    limite = Application.fetch_env!(:credit_engine, :circuit_breaker)[:limite_taxa_inadimplencia]

    %{
      "id" => "PROP-WEB",
      "taxa_inadimplencia_mercado" => to_string(limite / 2),
      "transacoes_noturnas" => to_string(centro.transacoes_noturnas),
      "dispositivos_novos" => to_string(centro.dispositivos_novos),
      "tentativas_login_falhas" => to_string(centro.tentativas_login_falhas),
      "comprometimento_renda" => "0.2",
      "atrasos_12m" => "0",
      "tempo_relacionamento_anos" => "5"
    }
    |> Map.merge(alteracoes)
  end

  defp etapas(resposta), do: Enum.map(resposta.etapas, & &1.resultado)

  describe "atributos/1" do
    test "converte texto em número, aceitando vírgula decimal" do
      atributos = API.atributos(parametros(%{"taxa_inadimplencia_mercado" => "0,05"}))

      assert atributos.macroeconomic_data.taxa_inadimplencia_mercado == 0.05
      assert atributos.behavioral_data.dispositivos_novos === 0
      assert atributos.open_finance_data.comprometimento_renda == 0.2
    end

    test "campo vazio vira nil e texto não numérico é mantido" do
      atributos =
        API.atributos(parametros(%{"atrasos_12m" => " ", "comprometimento_renda" => "abc"}))

      assert atributos.open_finance_data.atrasos_12m == nil
      assert atributos.open_finance_data.comprometimento_renda == "abc"
    end
  end

  describe "analisar/1" do
    test "a decisão é a mesma de CreditEngine.analisar/1" do
      p = parametros()
      assert {:ok, decisao} = CreditEngine.analisar(API.atributos(p))

      assert {200, resposta} = API.analisar(p)
      assert resposta.ok
      assert resposta.decisao == Map.from_struct(decisao)
      assert etapas(resposta) == [:passou, :passou, :passou, :passou, :passou]
      assert resposta.elixir =~ "%CreditEngine.Decision{"
    end

    test "recusa automática: só o Circuit Breaker roda" do
      assert {200, resposta} = API.analisar(parametros(%{"taxa_inadimplencia_mercado" => "0.99"}))

      assert resposta.decisao.status == :recusa_automatica

      assert etapas(resposta) == [
               :bloqueou,
               :nao_executada,
               :nao_executada,
               :nao_executada,
               :nao_executada
             ]

      assert resposta.distancia == nil
    end

    test "recusa de segurança: anomalias bloqueiam e a distância é informada" do
      maxima = Application.fetch_env!(:credit_engine, :anomalias)[:distancia_maxima]
      centro = Application.fetch_env!(:credit_engine, :anomalias)[:centro]
      noturnas = centro.transacoes_noturnas + maxima + 1

      assert {200, resposta} =
               API.analisar(parametros(%{"transacoes_noturnas" => to_string(noturnas)}))

      assert resposta.decisao.status == :recusa_seguranca

      assert etapas(resposta) == [
               :passou,
               :bloqueou,
               :nao_executada,
               :nao_executada,
               :nao_executada
             ]

      assert resposta.distancia > maxima
    end

    test "entrada inválida devolve 422 com o campo e o retorno em Elixir" do
      assert {422, resposta} = API.analisar(parametros(%{"comprometimento_renda" => "abc"}))

      refute resposta.ok
      assert resposta.erro.campo == :comprometimento_renda
      assert resposta.elixir == "{:error, {:dado_invalido, :comprometimento_renda}}"
    end

    test "campo vazio devolve dado ausente" do
      assert {422, resposta} = API.analisar(parametros(%{"atrasos_12m" => ""}))
      assert resposta.erro.campo == :atrasos_12m
      assert resposta.erro.mensagem =~ "ausente"
    end
  end
end
