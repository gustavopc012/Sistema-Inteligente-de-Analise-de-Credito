defmodule CreditEngine.Decision.Thresholds do
  @moduledoc """
  Ponto de extensão para critérios de decisão.
  Nenhum limiar provisório é definido neste módulo.
  """

  @spec classify(number()) :: {:error, :not_implemented}
  def classify(_score), do: {:error, :not_implemented}
end
