defmodule CreditEngine.Safety.CircuitBreaker do
  @moduledoc """
  Ponto de extensão para Circuit Breaker.
  Indicadores, acionamento e recuperação aguardam especificação.
  """

  @spec evaluate(map()) :: {:error, :not_implemented}
  def evaluate(_context), do: {:error, :not_implemented}
end
