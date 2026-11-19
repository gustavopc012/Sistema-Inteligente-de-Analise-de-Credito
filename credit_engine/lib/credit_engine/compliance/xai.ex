defmodule CreditEngine.Compliance.XAI do
  @moduledoc """
  Parecer explicável da decisão (T6).

  Usa a contribuição de cada campo do score (peso × valor), calculada por
  `CreditEngine.ML.Supervised.contribuicoes/1`, no lugar dos valores SHAP da
  arquitetura final.

  - Contribuição negativa reduz o risco: entra em `fatores_positivos`.
  - Contribuição positiva aumenta o risco: entra em `fatores_negativos`.
  - Contribuição zero não muda o risco e não entra em nenhuma das listas.

  Cada lista é ordenada pelo maior impacto (valor absoluto da contribuição).
  """

  alias CreditEngine.ML.Supervised
  alias CreditEngine.Proposal

  @type fator :: %{campo: atom(), contribuicao: float()}
  @type parecer :: %{fatores_positivos: [fator()], fatores_negativos: [fator()]}

  @spec explain(Proposal.t(), number()) :: {:ok, parecer()} | {:error, term()}
  def explain(%Proposal{} = proposal, probabilidade)
      when is_number(probabilidade) and probabilidade >= 0 and probabilidade <= 1 do
    with {:ok, contribuicoes} <- Supervised.contribuicoes(proposal) do
      fatores =
        Enum.map(contribuicoes, fn {campo, valor} -> %{campo: campo, contribuicao: valor} end)

      {:ok,
       %{
         fatores_positivos: fatores |> Enum.filter(&(&1.contribuicao < 0)) |> ordenar(),
         fatores_negativos: fatores |> Enum.filter(&(&1.contribuicao > 0)) |> ordenar()
       }}
    end
  end

  def explain(%Proposal{}, _probabilidade), do: {:error, {:dado_invalido, :probabilidade}}

  defp ordenar(fatores), do: Enum.sort_by(fatores, &abs(&1.contribuicao), :desc)
end
