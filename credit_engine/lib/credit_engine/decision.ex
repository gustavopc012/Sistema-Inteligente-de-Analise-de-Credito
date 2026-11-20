defmodule CreditEngine.Decision do
  @moduledoc """
  Decisão final da análise de crédito, devolvida por `CreditEngine.analisar/1`.

  - `status`: `:aprovado`, `:analise_manual`, `:recusado`,
    `:recusa_automatica` (Circuit Breaker) ou `:recusa_seguranca` (anomalia).
  - `score`: probabilidade de inadimplência, de 0 a 1.
  - `explanation`: parecer com `fatores_positivos` e `fatores_negativos`.

  Nas recusas automática e de segurança, `score` e `explanation` ficam `nil`.
  """

  defstruct [:status, :score, :explanation]

  @type t :: %__MODULE__{
          status:
            :aprovado | :analise_manual | :recusado | :recusa_automatica | :recusa_seguranca,
          score: number() | nil,
          explanation: map() | nil
        }
end
