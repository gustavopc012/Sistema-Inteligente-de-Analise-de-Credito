defmodule CreditEngine.ML.SupervisedTest do
  use ExUnit.Case, async: true

  alias CreditEngine.ML.Supervised
  alias CreditEngine.Proposal

  # Proposta sintética com os três campos usados pelo score.
  defp proposta(comprometimento, atrasos, tempo) do
    {:ok, proposal} =
      Proposal.new(%{
        id: "PROP-SCORE",
        open_finance_data: %{comprometimento_renda: comprometimento, atrasos_12m: atrasos},
        applicant_data: %{tempo_relacionamento_anos: tempo}
      })

    proposal
  end

  defp config, do: Application.fetch_env!(:credit_engine, :score)

  describe "predict/1 com os perfis de exemplo do plan.md (seção 7)" do
    test "bom pagador tem probabilidade próxima de 0,05" do
      assert {:ok, p} = Supervised.predict(proposta(0.2, 0, 5))
      assert_in_delta p, 0.05, 0.01
    end

    test "perfil intermediário tem probabilidade próxima de 0,43" do
      assert {:ok, p} = Supervised.predict(proposta(0.5, 1, 2))
      assert_in_delta p, 0.43, 0.01
    end

    test "mau pagador tem probabilidade próxima de 0,92" do
      assert {:ok, p} = Supervised.predict(proposta(0.8, 3, 1))
      assert_in_delta p, 0.92, 0.01
    end
  end

  describe "predict/1 — fórmula" do
    test "segue a função logística com o intercepto e os pesos da configuração" do
      pesos = config()[:pesos]

      z =
        config()[:intercepto] + pesos[:comprometimento_renda] * 0.4 + pesos[:atrasos_12m] * 2 +
          pesos[:tempo_relacionamento_anos] * 3

      assert {:ok, p} = Supervised.predict(proposta(0.4, 2, 3))
      assert_in_delta p, 1 / (1 + :math.exp(-z)), 1.0e-9
    end

    test "o resultado fica entre 0 e 1, inclusive com valores extremos" do
      for {comprometimento, atrasos, tempo} <- [{0, 0, 0}, {1, 1000, 0}, {0, 0, 10_000}] do
        assert {:ok, p} = Supervised.predict(proposta(comprometimento, atrasos, tempo))
        assert p >= 0 and p <= 1
      end
    end

    test "mais atrasos aumentam o risco" do
      {:ok, menos} = Supervised.predict(proposta(0.3, 0, 2))
      {:ok, mais} = Supervised.predict(proposta(0.3, 4, 2))

      assert mais > menos
    end

    test "mais tempo de relacionamento reduz o risco" do
      {:ok, pouco} = Supervised.predict(proposta(0.3, 1, 1))
      {:ok, muito} = Supervised.predict(proposta(0.3, 1, 10))

      assert muito < pouco
    end
  end

  describe "predict/1 — dados ausentes" do
    test "sem open_finance_data" do
      {:ok, proposal} =
        Proposal.new(%{id: "PROP-1", applicant_data: %{tempo_relacionamento_anos: 2}})

      assert {:error, {:dado_ausente, :comprometimento_renda}} = Supervised.predict(proposal)
    end

    test "sem o campo atrasos_12m" do
      {:ok, proposal} =
        Proposal.new(%{
          id: "PROP-2",
          open_finance_data: %{comprometimento_renda: 0.3},
          applicant_data: %{tempo_relacionamento_anos: 2}
        })

      assert {:error, {:dado_ausente, :atrasos_12m}} = Supervised.predict(proposal)
    end

    test "campo com nil" do
      assert {:error, {:dado_ausente, :tempo_relacionamento_anos}} =
               Supervised.predict(proposta(0.3, 1, nil))
    end
  end

  describe "predict/1 — dados inválidos" do
    test "valor não numérico" do
      assert {:error, {:dado_invalido, :atrasos_12m}} =
               Supervised.predict(proposta(0.3, "dois", 2))
    end

    test "comprometimento de renda fora de 0 a 1" do
      for valor <- [-0.1, 1.5] do
        assert {:error, {:dado_invalido, :comprometimento_renda}} =
                 Supervised.predict(proposta(valor, 1, 2))
      end
    end

    test "atrasos ou tempo negativos" do
      assert {:error, {:dado_invalido, :atrasos_12m}} = Supervised.predict(proposta(0.3, -1, 2))

      assert {:error, {:dado_invalido, :tempo_relacionamento_anos}} =
               Supervised.predict(proposta(0.3, 1, -2))
    end
  end

  describe "contribuicoes/1" do
    test "devolve peso × valor de cada campo" do
      pesos = config()[:pesos]

      assert {:ok, contribuicoes} = Supervised.contribuicoes(proposta(0.8, 3, 1))

      assert_in_delta contribuicoes.comprometimento_renda,
                      pesos[:comprometimento_renda] * 0.8,
                      1.0e-9

      assert_in_delta contribuicoes.atrasos_12m, pesos[:atrasos_12m] * 3, 1.0e-9

      assert_in_delta contribuicoes.tempo_relacionamento_anos,
                      pesos[:tempo_relacionamento_anos] * 1,
                      1.0e-9
    end
  end
end
