defmodule CreditEngine.ProposalTest do
  use ExUnit.Case, async: true

  alias CreditEngine.Proposal

  describe "new/1" do
    test "cria uma proposta com identificador válido" do
      assert {:ok, proposal} = Proposal.new(%{id: "PROP-001"})
      assert proposal.id == "PROP-001"
    end

    test "aceita mapas nos campos complementares" do
      attrs = %{
        id: "PROP-002",
        applicant_data: %{age: 30},
        open_finance_data: %{balance: 1500},
        behavioral_data: %{activity: "regular"},
        macroeconomic_data: %{inflation: 4.5}
      }

      assert {:ok, proposal} = Proposal.new(attrs)
      assert proposal.applicant_data == %{age: 30}
    end

    test "rejeita identificador vazio" do
      assert {:error, :invalid_id} = Proposal.new(%{id: ""})
    end

    test "rejeita proposta sem identificador" do
      assert {:error, :invalid_id} = Proposal.new(%{})
    end

    test "rejeita campos desconhecidos" do
      assert {:error, {:unknown_fields, [:invalid_field]}} =
               Proposal.new(%{id: "PROP-001", invalid_field: "valor"})
    end

    test "rejeita atributos que não sejam mapas" do
      assert {:error, :invalid_attributes} = Proposal.new("inválido")
    end

    test "rejeita campos complementares que não sejam mapas" do
      fields = [
        :applicant_data,
        :open_finance_data,
        :behavioral_data,
        :macroeconomic_data
      ]

      Enum.each(fields, fn field ->
        attrs = Map.put(%{id: "PROP-003"}, field, "inválido")

        assert {:error, {:invalid_field, ^field}} = Proposal.new(attrs)
      end)
    end
  end
end
