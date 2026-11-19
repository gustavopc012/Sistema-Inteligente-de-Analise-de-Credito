defmodule CreditEngine.ML.Unsupervised do
  @moduledoc """
  Detecção de anomalias comportamentais do sistema (T3).

  Calcula a distância euclidiana entre o comportamento da proposta e o centro
  de referência configurado em `config/config.exs` (`:anomalias`). Se a
  distância passar da distância máxima, a proposta é recusada por suspeita
  de fraude. No MVP, esta conta substitui o Isolation Forest e o K-Means
  previstos nos diagramas (plan.md, seção 3).

  Campos usados, todos em `behavioral_data` e maiores ou iguais a 0
  (plan.md, seção 6):

    * `transacoes_noturnas`;
    * `dispositivos_novos`;
    * `tentativas_login_falhas`.

  Distância igual à máxima não é anomalia: o plano diz que a proposta é
  recusada quando a distância passa do limite.
  """

  alias CreditEngine.Proposal

  @campos [:transacoes_noturnas, :dispositivos_novos, :tentativas_login_falhas]

  @type erro :: :suspeita_fraude | {:dado_ausente, atom()} | {:dado_invalido, atom()}

  @doc """
  Verifica se o comportamento da proposta está dentro da distância máxima
  do centro de referência.
  """
  @spec detect(Proposal.t()) :: {:ok, Proposal.t()} | {:error, erro()}
  def detect(%Proposal{} = proposal) do
    with {:ok, distancia} <- distancia(proposal) do
      if distancia > distancia_maxima() do
        {:error, :suspeita_fraude}
      else
        {:ok, proposal}
      end
    end
  end

  @doc """
  Calcula a distância euclidiana entre o comportamento da proposta e o
  centro de referência.
  """
  @spec distancia(Proposal.t()) ::
          {:ok, float()} | {:error, {:dado_ausente, atom()} | {:dado_invalido, atom()}}
  def distancia(%Proposal{behavioral_data: dados}) do
    centro = centro()

    Enum.reduce_while(@campos, {:ok, 0}, fn campo, {:ok, soma} ->
      case valor(dados, campo) do
        {:ok, valor} ->
          diferenca = valor - Map.fetch!(centro, campo)
          {:cont, {:ok, soma + diferenca * diferenca}}

        {:error, _motivo} = erro ->
          {:halt, erro}
      end
    end)
    |> case do
      {:ok, soma} -> {:ok, :math.sqrt(soma)}
      erro -> erro
    end
  end

  defp valor(dados, campo) when is_map(dados) do
    case Map.fetch(dados, campo) do
      :error -> {:error, {:dado_ausente, campo}}
      {:ok, nil} -> {:error, {:dado_ausente, campo}}
      {:ok, valor} when is_number(valor) and valor >= 0 -> {:ok, valor}
      {:ok, _valor} -> {:error, {:dado_invalido, campo}}
    end
  end

  defp valor(_dados, campo), do: {:error, {:dado_ausente, campo}}

  defp centro, do: config() |> Keyword.fetch!(:centro)
  defp distancia_maxima, do: config() |> Keyword.fetch!(:distancia_maxima)
  defp config, do: Application.fetch_env!(:credit_engine, :anomalias)
end
