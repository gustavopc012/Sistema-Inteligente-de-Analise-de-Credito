defmodule CreditEngine.ML.Supervised do
  @moduledoc """
  Score de risco do sistema (T4).

  Calcula a probabilidade de inadimplência de uma proposta com uma fórmula
  logística:

      probabilidade = 1 / (1 + e^(-z))
      z = intercepto + soma(peso * valor)

  O intercepto e os pesos vêm de `config/config.exs` (`:score`). No MVP, esta
  fórmula substitui o motor XGBoost previsto nos diagramas (plan.md, seção 3).

  Campos usados (plan.md, seção 6):

    * `open_finance_data.comprometimento_renda`, entre 0 e 1;
    * `open_finance_data.atrasos_12m`, maior ou igual a 0;
    * `applicant_data.tempo_relacionamento_anos`, maior ou igual a 0.
  """

  alias CreditEngine.Proposal

  # Cada campo do score e o mapa da proposta em que ele fica.
  @campos [
    comprometimento_renda: :open_finance_data,
    atrasos_12m: :open_finance_data,
    tempo_relacionamento_anos: :applicant_data
  ]

  @type erro :: {:dado_ausente, atom()} | {:dado_invalido, atom()}

  @doc """
  Calcula a probabilidade de inadimplência, sempre entre 0 e 1.
  """
  @spec predict(Proposal.t()) :: {:ok, float()} | {:error, erro()}
  def predict(%Proposal{} = proposal) do
    with {:ok, contribuicoes} <- contribuicoes(proposal) do
      z = intercepto() + (contribuicoes |> Map.values() |> Enum.sum())
      {:ok, logistica(z)}
    end
  end

  @doc """
  Devolve a contribuição (peso × valor) de cada campo para o score.

  Contribuição positiva aumenta o risco; negativa reduz. É a mesma conta
  usada por `predict/1` e serve de base para o parecer explicável (T6).
  """
  @spec contribuicoes(Proposal.t()) :: {:ok, %{atom() => float()}} | {:error, erro()}
  def contribuicoes(%Proposal{} = proposal) do
    pesos = pesos()

    Enum.reduce_while(@campos, {:ok, %{}}, fn {campo, mapa}, {:ok, acumulado} ->
      case valor(proposal, mapa, campo) do
        {:ok, valor} ->
          {:cont, {:ok, Map.put(acumulado, campo, Map.fetch!(pesos, campo) * valor)}}

        {:error, _motivo} = erro ->
          {:halt, erro}
      end
    end)
  end

  # Forma numericamente estável da função logística: evita estouro de
  # :math.exp/1 quando z é muito grande em valor absoluto.
  defp logistica(z) when z >= 0, do: 1 / (1 + :math.exp(-z))

  defp logistica(z) do
    e = :math.exp(z)
    e / (1 + e)
  end

  defp valor(proposal, mapa, campo) do
    proposal
    |> Map.get(mapa)
    |> buscar(campo)
    |> validar(campo)
  end

  defp buscar(dados, campo) when is_map(dados), do: Map.fetch(dados, campo)
  defp buscar(_dados, _campo), do: :error

  defp validar(:error, campo), do: {:error, {:dado_ausente, campo}}
  defp validar({:ok, nil}, campo), do: {:error, {:dado_ausente, campo}}

  defp validar({:ok, valor}, :comprometimento_renda)
       when is_number(valor) and valor >= 0 and valor <= 1,
       do: {:ok, valor}

  defp validar({:ok, valor}, campo)
       when campo != :comprometimento_renda and is_number(valor) and valor >= 0,
       do: {:ok, valor}

  defp validar({:ok, _valor}, campo), do: {:error, {:dado_invalido, campo}}

  defp intercepto, do: config() |> Keyword.fetch!(:intercepto)
  defp pesos, do: config() |> Keyword.fetch!(:pesos)
  defp config, do: Application.fetch_env!(:credit_engine, :score)
end
