defmodule CreditEngine.ML.Unsupervised do
  @moduledoc "Ponto de extensão para detecção não supervisionada."

  @spec detect(map()) :: {:error, :not_implemented}
  def detect(_features), do: {:error, :not_implemented}
end
