defmodule CreditEngine.CoreTest do
  use ExUnit.Case, async: true

  describe "create_proposal/1" do
    test "cria uma proposta válida" do
      assert {:ok, proposal} = CreditEngine.create_proposal(%{id: "PROP-001"})

      assert proposal.id == "PROP-001"
    end

    test "retorna erro para identificador inválido" do
      assert {:error, :invalid_id} = CreditEngine.create_proposal(%{id: ""})
    end

    test "retorna erro para atributos inválidos" do
      assert {:error, :invalid_attributes} = CreditEngine.create_proposal("dados inválidos")
    end
  end
end
