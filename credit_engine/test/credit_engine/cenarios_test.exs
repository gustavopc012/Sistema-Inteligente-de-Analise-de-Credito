defmodule CreditEngine.CenariosTest do
  @moduledoc """
  Testes de ponta a ponta dos cinco cenários do `docs/diagramas/sequencia.md`
  (critério de pronto do MVP, `plan.md`, seção 8).

  Os parâmetros (limite do Circuit Breaker, centro e distância máxima das
  anomalias, limiares) são lidos da configuração. Os perfis de score são os
  perfis de exemplo do `plan.md`, seção 7.
  """

  # async: false porque o pipeline passa pelo Circuit Breaker, que é um
  # processo único com contador global de bloqueios.
  use ExUnit.Case, async: false

  alias CreditEngine.Compliance.XAI
  alias CreditEngine.Decision
  alias CreditEngine.ML.Supervised
  alias CreditEngine.Proposal
  alias CreditEngine.Safety.CircuitBreaker

  defp config(chave), do: Application.fetch_env!(:credit_engine, chave)

  # Mercado normalizado: metade do limite configurado.
  defp taxa_normal, do: config(:circuit_breaker)[:limite_taxa_inadimplencia] / 2

  # Colapso de mercado: acima do limite configurado.
  defp taxa_colapso, do: config(:circuit_breaker)[:limite_taxa_inadimplencia] + 0.01

  # Comportamento padrão populacional: igual ao centro (distância 0).
  defp comportamento_padrao, do: config(:anomalias)[:centro]

  # Comportamento anômalo: distância até o centro maior que a máxima.
  defp comportamento_anomalo do
    excesso = config(:anomalias)[:distancia_maxima] + 1
    Map.update!(comportamento_padrao(), :transacoes_noturnas, &(&1 + excesso))
  end

  # Perfis de exemplo do plan.md, seção 7: {comprometimento, atrasos, tempo}.
  @bom_pagador {0.2, 0, 5}
  @intermediario {0.5, 1, 2}
  @mau_pagador {0.8, 3, 1}

  # Proposta sintética com o perfil completo do proponente.
  defp perfil_completo(taxa, comportamento, {comprometimento, atrasos, tempo}) do
    %{
      id: "PROP-CENARIO",
      macroeconomic_data: %{taxa_inadimplencia_mercado: taxa},
      behavioral_data: comportamento,
      open_finance_data: %{comprometimento_renda: comprometimento, atrasos_12m: atrasos},
      applicant_data: %{tempo_relacionamento_anos: tempo}
    }
  end

  defp campos(fatores), do: Enum.map(fatores, & &1.campo)

  defp ordenado_por_impacto?(fatores) do
    impactos = Enum.map(fatores, &abs(&1.contribuicao))
    impactos == Enum.sort(impactos, :desc)
  end

  # Confere a decisão de quem chega ao fim do fluxo: o score é o do modelo de
  # risco para a proposta, e o parecer é o do XAI para a proposta e esse score.
  defp assert_fluxo_completo(atributos, %Decision{} = decisao) do
    {:ok, proposal} = Proposal.new(atributos)

    assert {:ok, decisao.score} == Supervised.predict(proposal)
    assert {:ok, decisao.explanation} == XAI.explain(proposal, decisao.score)
  end

  describe "Funcionalidade: decisão de crédito com proteção sistêmica, detecção de fraude e explicabilidade" do
    test "Cenário 1: recusa automática por colapso de mercado" do
      atributos = perfil_completo(taxa_colapso(), comportamento_padrao(), @bom_pagador)
      bloqueios_antes = CircuitBreaker.status().bloqueios

      assert CreditEngine.analisar(atributos) ==
               {:ok, %Decision{status: :recusa_automatica, score: nil, explanation: nil}}

      # O Circuit Breaker retornou "Block".
      assert CircuitBreaker.status().bloqueios == bloqueios_antes + 1

      # O Clustering e o XGBoost não são executados: sem os dados que eles
      # usam, a decisão é a mesma. Se rodassem, o resultado seria dado_ausente.
      so_macro = Map.take(atributos, [:id, :macroeconomic_data])

      assert {:ok, %Decision{status: :recusa_automatica}} = CreditEngine.analisar(so_macro)
    end

    test "Cenário 2: recusa de segurança por suspeita de fraude ou bot" do
      atributos = perfil_completo(taxa_normal(), comportamento_anomalo(), @bom_pagador)
      bloqueios_antes = CircuitBreaker.status().bloqueios

      assert CreditEngine.analisar(atributos) ==
               {:ok, %Decision{status: :recusa_seguranca, score: nil, explanation: nil}}

      # O Circuit Breaker retornou "Pass".
      assert CircuitBreaker.status().bloqueios == bloqueios_antes

      # O XGBoost não é executado: sem os dados do score, a decisão é a mesma.
      # Se rodasse, o resultado seria dado_ausente.
      sem_dados_do_score = Map.drop(atributos, [:open_finance_data, :applicant_data])

      assert {:ok, %Decision{status: :recusa_seguranca}} =
               CreditEngine.analisar(sem_dados_do_score)
    end

    test "Cenário 3: crédito aprovado com explicabilidade" do
      atributos = perfil_completo(taxa_normal(), comportamento_padrao(), @bom_pagador)

      assert {:ok, %Decision{status: :aprovado} = decisao} = CreditEngine.analisar(atributos)
      assert decisao.score < config(:limiares)[:aprovado_abaixo_de]
      assert_fluxo_completo(atributos, decisao)

      # Parecer com fatores de impacto positivo e negativo.
      assert campos(decisao.explanation.fatores_positivos) == [:tempo_relacionamento_anos]
      assert campos(decisao.explanation.fatores_negativos) == [:comprometimento_renda]
    end

    test "Cenário 4: crédito recusado pelo modelo de risco com explicabilidade" do
      atributos = perfil_completo(taxa_normal(), comportamento_padrao(), @mau_pagador)

      assert {:ok, %Decision{status: :recusado} = decisao} = CreditEngine.analisar(atributos)
      assert decisao.score > config(:limiares)[:recusado_acima_de]
      assert_fluxo_completo(atributos, decisao)

      # Parecer com os fatores que mais pesaram na recusa, do maior impacto
      # para o menor.
      negativos = decisao.explanation.fatores_negativos

      assert Enum.sort(campos(negativos)) == [:atrasos_12m, :comprometimento_renda]
      assert ordenado_por_impacto?(negativos)
    end

    test "Cenário 5: análise manual (condicional) com explicabilidade" do
      atributos = perfil_completo(taxa_normal(), comportamento_padrao(), @intermediario)

      assert {:ok, %Decision{status: :analise_manual} = decisao} =
               CreditEngine.analisar(atributos)

      assert decisao.score >= config(:limiares)[:aprovado_abaixo_de]
      assert decisao.score <= config(:limiares)[:recusado_acima_de]
      assert_fluxo_completo(atributos, decisao)

      # Parecer explicativo.
      assert campos(decisao.explanation.fatores_positivos) == [:tempo_relacionamento_anos]

      assert campos(decisao.explanation.fatores_negativos) == [
               :comprometimento_renda,
               :atrasos_12m
             ]
    end
  end
end
