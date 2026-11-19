defmodule CreditEngine.Compliance.XAITest do
  use ExUnit.Case, async: true

  alias CreditEngine.Compliance.XAI
  alias CreditEngine.ML.Supervised
  alias CreditEngine.Proposal

  # Proposta sintética com os três campos usados pelo score e pelo parecer.
  defp proposta(comprometimento, atrasos, tempo) do
    {:ok, proposal} =
      Proposal.new(%{
        id: "PROP-XAI",
        open_finance_data: %{comprometimento_renda: comprometimento, atrasos_12m: atrasos},
        applicant_data: %{tempo_relacionamento_anos: tempo}
      })

    proposal
  end

  defp parecer(proposal) do
    {:ok, p} = Supervised.predict(proposal)
    XAI.explain(proposal, p)
  end

  defp campos(fatores), do: Enum.map(fatores, & &1.campo)

  describe "explain/2 com os perfis de exemplo do plan.md (seção 7)" do
    test "mau pagador: comprometimento de renda e atrasos aumentam o risco" do
      assert {:ok, parecer} = parecer(proposta(0.8, 3, 1))

      assert Enum.sort(campos(parecer.fatores_negativos)) == [
               :atrasos_12m,
               :comprometimento_renda
             ]
    end

    test "mau pagador: tempo de relacionamento reduz o risco" do
      assert {:ok, parecer} = parecer(proposta(0.8, 3, 1))

      assert [%{campo: :tempo_relacionamento_anos, contribuicao: c}] = parecer.fatores_positivos
      assert_in_delta c, -0.3, 1.0e-9
    end

    test "bom pagador sem atrasos: atrasos não entram em nenhuma lista" do
      assert {:ok, parecer} = parecer(proposta(0.2, 0, 5))

      assert campos(parecer.fatores_positivos) == [:tempo_relacionamento_anos]
      assert campos(parecer.fatores_negativos) == [:comprometimento_renda]
    end
  end

  describe "explain/2 — contribuições e ordenação" do
    test "a contribuição de cada fator é peso × valor" do
      proposal = proposta(0.5, 1, 2)
      assert {:ok, parecer} = parecer(proposal)
      assert {:ok, esperado} = Supervised.contribuicoes(proposal)

      for fator <- parecer.fatores_positivos ++ parecer.fatores_negativos do
        assert fator.contribuicao == Map.fetch!(esperado, fator.campo)
        assert is_float(fator.contribuicao)
      end
    end

    test "fatores negativos ficam ordenados do maior para o menor impacto" do
      # Perfil intermediário: comprometimento 3,0 × 0,5 = 1,5; atrasos 0,8 × 1 = 0,8
      assert {:ok, parecer} = parecer(proposta(0.5, 1, 2))

      assert campos(parecer.fatores_negativos) == [:comprometimento_renda, :atrasos_12m]
    end

    test "a ordenação usa o impacto, e não a ordem dos campos" do
      # comprometimento 3,0 × 0,1 = 0,3; atrasos 0,8 × 5 = 4,0
      assert {:ok, parecer} = parecer(proposta(0.1, 5, 0))

      assert campos(parecer.fatores_negativos) == [:atrasos_12m, :comprometimento_renda]
      assert parecer.fatores_positivos == []
    end
  end

  describe "explain/2 — erros" do
    test "campo ausente devolve dado_ausente" do
      {:ok, proposal} =
        Proposal.new(%{
          id: "PROP-XAI",
          open_finance_data: %{comprometimento_renda: 0.5},
          applicant_data: %{tempo_relacionamento_anos: 2}
        })

      assert XAI.explain(proposal, 0.4) == {:error, {:dado_ausente, :atrasos_12m}}
    end

    test "campo inválido devolve dado_invalido" do
      assert XAI.explain(proposta(1.5, 1, 2), 0.4) ==
               {:error, {:dado_invalido, :comprometimento_renda}}
    end

    test "probabilidade fora de 0 a 1 ou não numérica devolve dado_invalido" do
      proposal = proposta(0.5, 1, 2)

      for p <- [-0.1, 1.5, "0.4", nil] do
        assert XAI.explain(proposal, p) == {:error, {:dado_invalido, :probabilidade}}
      end
    end
  end
end
