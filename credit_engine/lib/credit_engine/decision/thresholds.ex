defmodule CreditEngine.Decision.Thresholds do
  @moduledoc """
  Limiares de decisão do sistema (T5).

  Transforma a probabilidade de inadimplência calculada pelo score (T4) em um
  status, usando os limiares de `config/config.exs` (`:limiares`):

    * abaixo de `aprovado_abaixo_de`: `:aprovado`;
    * acima de `recusado_acima_de`: `:recusado`;
    * entre os dois, inclusive nos próprios limites: `:analise_manual`.

  A probabilidade precisa ser um número entre 0 e 1.
  """

  @type status :: :aprovado | :analise_manual | :recusado

  @doc """
  Classifica a probabilidade de inadimplência em um status de decisão.
  """
  @spec classify(number()) :: {:ok, status()} | {:error, {:dado_invalido, :probabilidade}}
  def classify(probabilidade)
      when is_number(probabilidade) and probabilidade >= 0 and probabilidade <= 1 do
    config = Application.fetch_env!(:credit_engine, :limiares)

    cond do
      probabilidade < Keyword.fetch!(config, :aprovado_abaixo_de) -> {:ok, :aprovado}
      probabilidade > Keyword.fetch!(config, :recusado_acima_de) -> {:ok, :recusado}
      true -> {:ok, :analise_manual}
    end
  end

  def classify(_probabilidade), do: {:error, {:dado_invalido, :probabilidade}}
end
