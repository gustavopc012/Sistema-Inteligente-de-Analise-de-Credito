defmodule CreditEngine.Decision do
  @moduledoc """
  Estrutura provisória para representar um resultado.
  Os status e critérios definitivos ainda não foram especificados.
  """

  defstruct [:status, :score, :explanation]

  @type t :: %__MODULE__{
          status: atom() | nil,
          score: number() | nil,
          explanation: map() | nil
        }
end
