defmodule CreditEngine.PipelineTest do
  # async: false porque o pipeline passa pelo Circuit Breaker, que é um
  # processo único com contador global.
  use ExUnit.Case, async: false

  alias CreditEngine.Decision

  # Comportamento igual ao centro de referência (distância 0) e taxa de
  # inadimplência abaixo do limite: passa pelo Circuit Breaker e pelas anomalias.
  defp atributos(opcoes \\ []) do
    %{
      id: "PROP-PIPELINE",
      macroeconomic_data: %{taxa_inadimplencia_mercado: Keyword.get(opcoes, :taxa, 0.05)},
      behavioral_data: %{
        transacoes_noturnas: Keyword.get(opcoes, :transacoes_noturnas, 2),
        dispositivos_novos: 0,
        tentativas_login_falhas: 1
      },
      open_finance_data: %{
        comprometimento_renda: Keyword.get(opcoes, :comprometimento, 0.2),
        atrasos_12m: Keyword.get(opcoes, :atrasos, 0)
      },
      applicant_data: %{tempo_relacionamento_anos: Keyword.get(opcoes, :tempo, 5)}
    }
  end

  describe "analisar/1 — um teste por status" do
    test "bom pagador é aprovado, com score e parecer" do
      assert {:ok, %Decision{status: :aprovado, score: score, explanation: parecer}} =
               CreditEngine.analisar(atributos())

      assert_in_delta score, 0.05, 0.01
      assert %{fatores_positivos: [_ | _], fatores_negativos: [_ | _]} = parecer
    end

    test "perfil intermediário vai para análise manual, com score e parecer" do
      assert {:ok, %Decision{status: :analise_manual, score: score, explanation: parecer}} =
               CreditEngine.analisar(atributos(comprometimento: 0.5, atrasos: 1, tempo: 2))

      assert_in_delta score, 0.43, 0.01

      assert Enum.map(parecer.fatores_negativos, & &1.campo) == [
               :comprometimento_renda,
               :atrasos_12m
             ]
    end

    test "mau pagador é recusado, com score e parecer" do
      assert {:ok, %Decision{status: :recusado, score: score, explanation: parecer}} =
               CreditEngine.analisar(atributos(comprometimento: 0.8, atrasos: 3, tempo: 1))

      assert_in_delta score, 0.92, 0.01
      assert [%{campo: :tempo_relacionamento_anos}] = parecer.fatores_positivos
    end

    test "crise sistêmica gera recusa automática, sem score nem parecer" do
      assert CreditEngine.analisar(atributos(taxa: 0.10)) ==
               {:ok, %Decision{status: :recusa_automatica, score: nil, explanation: nil}}
    end

    test "comportamento anômalo gera recusa de segurança, sem score nem parecer" do
      assert CreditEngine.analisar(atributos(transacoes_noturnas: 10)) ==
               {:ok, %Decision{status: :recusa_seguranca, score: nil, explanation: nil}}
    end
  end

  describe "analisar/1 — ordem das etapas" do
    test "o Circuit Breaker vem antes da detecção de anomalias" do
      assert {:ok, %Decision{status: :recusa_automatica}} =
               CreditEngine.analisar(atributos(taxa: 0.10, transacoes_noturnas: 10))
    end

    test "a detecção de anomalias vem antes do score" do
      # Perfil de mau pagador, mas com comportamento anômalo.
      assert {:ok, %Decision{status: :recusa_seguranca}} =
               CreditEngine.analisar(
                 atributos(transacoes_noturnas: 10, comprometimento: 0.8, atrasos: 3, tempo: 1)
               )
    end
  end

  describe "analisar/1 — entrada inválida" do
    test "proposta inválida devolve o erro da validação" do
      assert CreditEngine.analisar(%{atributos() | id: ""}) == {:error, :invalid_id}
      assert CreditEngine.analisar("dados inválidos") == {:error, :invalid_attributes}
    end

    test "campo ausente devolve dado_ausente" do
      attrs = Map.delete(atributos(), :macroeconomic_data)

      assert CreditEngine.analisar(attrs) ==
               {:error, {:dado_ausente, :taxa_inadimplencia_mercado}}
    end

    test "campo inválido devolve dado_invalido" do
      assert CreditEngine.analisar(atributos(comprometimento: 1.5)) ==
               {:error, {:dado_invalido, :comprometimento_renda}}
    end
  end
end
