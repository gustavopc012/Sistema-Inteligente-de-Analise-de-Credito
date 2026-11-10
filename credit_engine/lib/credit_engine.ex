defmodule CreditEngine do
  @moduledoc """
  Ponto de entrada do Sistema Inteligente de Análise de Crédito.
  """

  alias CreditEngine.Proposal

  @spec name() :: String.t()
  def name, do: "Sistema Inteligente de Análise de Crédito"

  @doc """
  Recebe os atributos e cria uma proposta de crédito validada.
  """
  @spec create_proposal(map()) :: {:ok, Proposal.t()} | {:error, term()}
  def create_proposal(attrs) do
    Proposal.new(attrs)
  end
end
