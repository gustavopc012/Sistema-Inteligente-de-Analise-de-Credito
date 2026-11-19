defmodule CreditEngineTest do
  use ExUnit.Case, async: true

  test "identifica o projeto" do
    assert CreditEngine.name() == "Sistema Inteligente de Análise de Crédito"
  end

  test "cria uma proposta com identificador" do
    proposal = %CreditEngine.Proposal{id: "proposal-test-001"}
    assert proposal.id == "proposal-test-001"
    assert proposal.applicant_data == nil
  end
end
