defmodule CreditEngine do
  @moduledoc """
  Ponto de entrada do Sistema Inteligente de Análise de Crédito.
  """

  alias CreditEngine.Compliance.XAI
  alias CreditEngine.Decision
  alias CreditEngine.Decision.Thresholds
  alias CreditEngine.ML.{Supervised, Unsupervised}
  alias CreditEngine.Proposal
  alias CreditEngine.Safety.CircuitBreaker

  @spec name() :: String.t()
  def name, do: "Sistema Inteligente de Análise de Crédito"

  @doc """
  Recebe os atributos e cria uma proposta de crédito validada.
  """
  @spec create_proposal(map()) :: {:ok, Proposal.t()} | {:error, term()}
  def create_proposal(attrs) do
    Proposal.new(attrs)
  end

  @doc """
  Analisa uma proposta de crédito do início ao fim (T7).

  Etapas, nesta ordem: validação da proposta, Circuit Breaker, detecção de
  anomalias, score de risco, limiares de decisão e parecer explicável.

  - Crise sistêmica no Circuit Breaker: `%Decision{status: :recusa_automatica}`.
  - Suspeita de fraude na detecção de anomalias: `%Decision{status: :recusa_seguranca}`.
  - Nos dois casos acima a decisão não traz score nem parecer.
  - Caso contrário: `:aprovado`, `:analise_manual` ou `:recusado`, com a
    probabilidade de inadimplência em `score` e o parecer em `explanation`.

  Entrada inválida devolve `{:error, motivo}`, com o motivo da etapa que falhou.
  """
  @spec analisar(map()) :: {:ok, Decision.t()} | {:error, term()}
  def analisar(atributos) do
    with {:ok, proposal} <- Proposal.new(atributos),
         {:ok, proposal} <- CircuitBreaker.evaluate(proposal),
         {:ok, proposal} <- Unsupervised.detect(proposal),
         {:ok, probabilidade} <- Supervised.predict(proposal),
         {:ok, status} <- Thresholds.classify(probabilidade),
         {:ok, parecer} <- XAI.explain(proposal, probabilidade) do
      {:ok, %Decision{status: status, score: probabilidade, explanation: parecer}}
    else
      {:error, :crise_sistemica} -> {:ok, %Decision{status: :recusa_automatica}}
      {:error, :suspeita_fraude} -> {:ok, %Decision{status: :recusa_seguranca}}
      {:error, _motivo} = erro -> erro
    end
  end
end
