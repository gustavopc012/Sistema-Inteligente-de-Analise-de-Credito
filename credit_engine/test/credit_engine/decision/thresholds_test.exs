defmodule CreditEngine.Decision.ThresholdsTest do
  use ExUnit.Case, async: true

  alias CreditEngine.Decision.Thresholds

  defp config, do: Application.fetch_env!(:credit_engine, :limiares)
  defp aprovado_abaixo_de, do: config()[:aprovado_abaixo_de]
  defp recusado_acima_de, do: config()[:recusado_acima_de]

  describe "classify/1 com os exemplos do sequencia.md" do
    test "0,15 é aprovado" do
      assert {:ok, :aprovado} = Thresholds.classify(0.15)
    end

    test "0,40 vai para análise manual" do
      assert {:ok, :analise_manual} = Thresholds.classify(0.40)
    end

    test "0,80 é recusado" do
      assert {:ok, :recusado} = Thresholds.classify(0.80)
    end
  end

  describe "classify/1 — limites" do
    test "valor exatamente no limite de aprovação vai para análise manual" do
      assert {:ok, :analise_manual} = Thresholds.classify(aprovado_abaixo_de())
    end

    test "valor exatamente no limite de recusa vai para análise manual" do
      assert {:ok, :analise_manual} = Thresholds.classify(recusado_acima_de())
    end

    test "valor logo abaixo do limite de aprovação é aprovado" do
      assert {:ok, :aprovado} = Thresholds.classify(aprovado_abaixo_de() - 0.001)
    end

    test "valor logo acima do limite de recusa é recusado" do
      assert {:ok, :recusado} = Thresholds.classify(recusado_acima_de() + 0.001)
    end

    test "os extremos 0 e 1 são aceitos" do
      assert {:ok, :aprovado} = Thresholds.classify(0)
      assert {:ok, :recusado} = Thresholds.classify(1)
    end
  end

  describe "classify/1 — dados inválidos" do
    test "probabilidade fora de 0 a 1" do
      for valor <- [-0.1, 1.5] do
        assert {:error, {:dado_invalido, :probabilidade}} = Thresholds.classify(valor)
      end
    end

    test "probabilidade não numérica ou nil" do
      for valor <- ["0.4", nil] do
        assert {:error, {:dado_invalido, :probabilidade}} = Thresholds.classify(valor)
      end
    end
  end
end
