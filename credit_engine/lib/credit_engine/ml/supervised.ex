defmodule CreditEngine.ML.Supervised do
  @moduledoc "Ponto de extensão para o componente supervisionado."

  @spec predict(map()) :: {:error, :not_implemented}
  def predict(_features), do: {:error, :not_implemented}
end
