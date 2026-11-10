defmodule CreditEngine.Proposal do
  @moduledoc """
  Representa uma proposta de crédito recebida pelo sistema.
  """

  @enforce_keys [:id]
  defstruct [
    :id,
    :applicant_data,
    :open_finance_data,
    :behavioral_data,
    :macroeconomic_data
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          applicant_data: map() | nil,
          open_finance_data: map() | nil,
          behavioral_data: map() | nil,
          macroeconomic_data: map() | nil
        }

  @optional_map_fields [
    :applicant_data,
    :open_finance_data,
    :behavioral_data,
    :macroeconomic_data
  ]

  @doc """
  Cria uma proposta a partir de um mapa de atributos.
  """
  def new(attrs) when is_map(attrs) do
    attrs =
      Map.new(attrs, fn
        {key, value} when is_binary(key) ->
          {String.to_existing_atom(key), value}

        pair ->
          pair
      end)

    allowed_keys = [:id | @optional_map_fields]
    unknown_keys = Map.keys(attrs) -- allowed_keys

    cond do
      unknown_keys != [] ->
        {:error, {:unknown_fields, unknown_keys}}

      not is_binary(Map.get(attrs, :id)) or Map.get(attrs, :id) == "" ->
        {:error, :invalid_id}

      true ->
        validate_optional_fields(attrs)
    end
  rescue
    ArgumentError ->
      {:error, :invalid_fields}
  end

  def new(_attrs), do: {:error, :invalid_attributes}

  defp validate_optional_fields(attrs) do
    case Enum.find(@optional_map_fields, fn field ->
           value = Map.get(attrs, field)
           not (is_nil(value) or is_map(value))
         end) do
      nil ->
        {:ok, struct!(__MODULE__, attrs)}

      field ->
        {:error, {:invalid_field, field}}
    end
  end
end
