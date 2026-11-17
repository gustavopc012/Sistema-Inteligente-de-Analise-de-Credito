defmodule CreditEngine.ConfigTest do
  use ExUnit.Case, async: true

  describe "valores de demonstração (plan.md, seção 7)" do
    test "Circuit Breaker tem limite entre 0 e 1" do
      config = Application.fetch_env!(:credit_engine, :circuit_breaker)
      limite = Keyword.fetch!(config, :limite_taxa_inadimplencia)

      assert is_number(limite) and limite > 0 and limite < 1
    end

    test "anomalias têm centro com os três campos e distância positiva" do
      config = Application.fetch_env!(:credit_engine, :anomalias)
      centro = Keyword.fetch!(config, :centro)

      assert Map.keys(centro) |> Enum.sort() ==
               [:dispositivos_novos, :tentativas_login_falhas, :transacoes_noturnas]

      assert Enum.all?(Map.values(centro), &is_number/1)
      assert Keyword.fetch!(config, :distancia_maxima) > 0
    end

    test "score tem intercepto e pesos numéricos para os três campos" do
      config = Application.fetch_env!(:credit_engine, :score)
      pesos = Keyword.fetch!(config, :pesos)

      assert is_number(Keyword.fetch!(config, :intercepto))

      assert Map.keys(pesos) |> Enum.sort() ==
               [:atrasos_12m, :comprometimento_renda, :tempo_relacionamento_anos]

      assert Enum.all?(Map.values(pesos), &is_number/1)
    end

    test "limiares estão entre 0 e 1 e em ordem" do
      config = Application.fetch_env!(:credit_engine, :limiares)
      aprovado = Keyword.fetch!(config, :aprovado_abaixo_de)
      recusado = Keyword.fetch!(config, :recusado_acima_de)

      assert 0 < aprovado and aprovado < recusado and recusado < 1
    end
  end
end
