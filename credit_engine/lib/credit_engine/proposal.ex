defmodule CreditEngine.Proposal do
  @moduledoc """
  Estrutura inicial e provisória de uma proposta.
  O contrato definitivo deve ser aprovado pela equipe.
  """

  @enforce_keys [:id]
  defstruct [:id, :applicant_data, :open_finance_data, :behavioral_data, :macroeconomic_data]

  @type t :: %__MODULE__{
          id: String.t(),
          applicant_data: map() | nil,
          open_finance_data: map() | nil,
          behavioral_data: map() | nil,
          macroeconomic_data: map() | nil
        }
end
