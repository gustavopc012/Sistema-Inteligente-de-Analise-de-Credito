defmodule CreditEngine.ML.UnsupervisedTest do
  use ExUnit.Case, async: true

  alias CreditEngine.ML.Unsupervised
  alias CreditEngine.Proposal

  defp config, do: Application.fetch_env!(:credit_engine, :anomalias)
  defp centro, do: config()[:centro]
  defp distancia_maxima, do: config()[:distancia_maxima]

  # Proposta sintética com o comportamento informado.
  defp proposta(comportamento) do
    {:ok, proposal} = Proposal.new(%{id: "PROP-ANOMALIA", behavioral_data: comportamento})
    proposal
  end

  # Comportamento deslocado do centro apenas em transacoes_noturnas.
  defp deslocado(deslocamento) do
    Map.update!(centro(), :transacoes_noturnas, &(&1 + deslocamento))
  end

  describe "detect/1" do
    test "comportamento igual ao centro é aceito" do
      proposal = proposta(centro())
      assert {:ok, ^proposal} = Unsupervised.detect(proposal)
    end

    test "comportamento próximo do centro é aceito" do
      proposal = proposta(deslocado(distancia_maxima() / 2))
      assert {:ok, ^proposal} = Unsupervised.detect(proposal)
    end

    test "distância igual à máxima não é anomalia" do
      proposal = proposta(deslocado(distancia_maxima()))
      assert {:ok, ^proposal} = Unsupervised.detect(proposal)
    end

    test "distância acima da máxima é suspeita de fraude" do
      assert {:error, :suspeita_fraude} =
               Unsupervised.detect(proposta(deslocado(distancia_maxima() + 0.1)))
    end

    test "comportamento muito diferente em todos os campos é suspeita de fraude" do
      comportamento = %{transacoes_noturnas: 8, dispositivos_novos: 4, tentativas_login_falhas: 6}

      assert {:error, :suspeita_fraude} = Unsupervised.detect(proposta(comportamento))
    end
  end

  describe "distancia/1" do
    test "calcula a distância euclidiana até o centro" do
      comportamento = %{
        transacoes_noturnas: centro().transacoes_noturnas + 3,
        dispositivos_novos: centro().dispositivos_novos + 4,
        tentativas_login_falhas: centro().tentativas_login_falhas
      }

      assert {:ok, distancia} = Unsupervised.distancia(proposta(comportamento))
      assert_in_delta distancia, 5.0, 1.0e-9
    end
  end

  describe "detect/1 — dados ausentes" do
    test "sem behavioral_data" do
      {:ok, proposal} = Proposal.new(%{id: "PROP-1"})

      assert {:error, {:dado_ausente, :transacoes_noturnas}} = Unsupervised.detect(proposal)
    end

    test "sem um dos campos" do
      comportamento = Map.delete(centro(), :dispositivos_novos)

      assert {:error, {:dado_ausente, :dispositivos_novos}} =
               Unsupervised.detect(proposta(comportamento))
    end

    test "campo com nil" do
      comportamento = Map.put(centro(), :tentativas_login_falhas, nil)

      assert {:error, {:dado_ausente, :tentativas_login_falhas}} =
               Unsupervised.detect(proposta(comportamento))
    end
  end

  describe "detect/1 — dados inválidos" do
    test "valor não numérico" do
      comportamento = Map.put(centro(), :transacoes_noturnas, "muitas")

      assert {:error, {:dado_invalido, :transacoes_noturnas}} =
               Unsupervised.detect(proposta(comportamento))
    end

    test "valor negativo" do
      comportamento = Map.put(centro(), :dispositivos_novos, -1)

      assert {:error, {:dado_invalido, :dispositivos_novos}} =
               Unsupervised.detect(proposta(comportamento))
    end
  end
end
