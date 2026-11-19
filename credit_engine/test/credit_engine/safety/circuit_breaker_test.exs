defmodule CreditEngine.Safety.CircuitBreakerTest do
  # async: false porque o Circuit Breaker é um processo único, com contador global.
  use ExUnit.Case, async: false

  alias CreditEngine.Proposal
  alias CreditEngine.Safety.CircuitBreaker

  defp limite do
    Application.fetch_env!(:credit_engine, :circuit_breaker)[:limite_taxa_inadimplencia]
  end

  defp proposta(macroeconomic_data) do
    {:ok, proposal} =
      Proposal.new(%{id: "proposta-sintetica-001", macroeconomic_data: macroeconomic_data})

    proposal
  end

  describe "evaluate/1" do
    test "taxa abaixo do limite devolve {:ok, proposal}" do
      proposal = proposta(%{taxa_inadimplencia_mercado: limite() / 2})

      assert {:ok, ^proposal} = CircuitBreaker.evaluate(proposal)
    end

    test "taxa exatamente no limite não bloqueia" do
      proposal = proposta(%{taxa_inadimplencia_mercado: limite()})

      assert {:ok, ^proposal} = CircuitBreaker.evaluate(proposal)
    end

    test "taxa acima do limite devolve {:error, :crise_sistemica}" do
      proposal = proposta(%{taxa_inadimplencia_mercado: limite() + 0.01})

      assert {:error, :crise_sistemica} = CircuitBreaker.evaluate(proposal)
    end

    test "campo ausente devolve dado_ausente" do
      assert {:error, {:dado_ausente, :taxa_inadimplencia_mercado}} =
               CircuitBreaker.evaluate(proposta(%{}))
    end

    test "macroeconomic_data nil devolve dado_ausente" do
      assert {:error, {:dado_ausente, :taxa_inadimplencia_mercado}} =
               CircuitBreaker.evaluate(proposta(nil))
    end

    test "valor não numérico devolve dado_invalido" do
      proposal = proposta(%{taxa_inadimplencia_mercado: "alta"})

      assert {:error, {:dado_invalido, :taxa_inadimplencia_mercado}} =
               CircuitBreaker.evaluate(proposal)
    end

    test "taxa negativa devolve dado_invalido" do
      proposal = proposta(%{taxa_inadimplencia_mercado: -0.5})

      assert {:error, {:dado_invalido, :taxa_inadimplencia_mercado}} =
               CircuitBreaker.evaluate(proposal)
    end

    test "taxa maior que 1 devolve dado_invalido e não conta como bloqueio" do
      antes = CircuitBreaker.status().bloqueios
      proposal = proposta(%{taxa_inadimplencia_mercado: 3})

      assert {:error, {:dado_invalido, :taxa_inadimplencia_mercado}} =
               CircuitBreaker.evaluate(proposal)

      assert CircuitBreaker.status().bloqueios == antes
    end

    test "os extremos 0 e 1 são taxas válidas" do
      assert {:ok, _} = CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: 0}))

      assert {:error, :crise_sistemica} =
               CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: 1}))
    end
  end

  describe "status/0" do
    test "informa o limite em uso" do
      assert %{limite: limite} = CircuitBreaker.status()
      assert limite == limite()
    end

    test "conta os bloqueios" do
      antes = CircuitBreaker.status().bloqueios

      CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: limite() + 0.01}))
      CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: limite() + 0.02}))

      assert CircuitBreaker.status().bloqueios == antes + 2
    end

    test "propostas aprovadas ou com erro de dado não contam como bloqueio" do
      antes = CircuitBreaker.status().bloqueios

      CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: limite() / 2}))
      CircuitBreaker.evaluate(proposta(%{}))
      CircuitBreaker.evaluate(proposta(%{taxa_inadimplencia_mercado: "alta"}))

      assert CircuitBreaker.status().bloqueios == antes
    end
  end

  describe "supervisão" do
    test "o processo aparece sob o supervisor da aplicação" do
      filhos = Supervisor.which_children(CreditEngine.Supervisor)

      assert Enum.any?(filhos, fn {id, pid, _tipo, _modulos} ->
               id == CircuitBreaker and is_pid(pid)
             end)
    end
  end
end
