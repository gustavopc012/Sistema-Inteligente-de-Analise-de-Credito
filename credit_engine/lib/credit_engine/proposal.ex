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

  @allowed_fields [:id | @optional_map_fields]

  # Converte nomes de campo em texto para os átomos conhecidos sem criar
  # átomos novos. Chaves em texto desconhecidas permanecem em texto.
  @field_names Map.new(@allowed_fields, &{Atom.to_string(&1), &1})

  @doc """
  Cria uma proposta a partir de um mapa de atributos.
  """
  def new(attrs) when is_map(attrs) do
    attrs = Map.new(attrs, fn {key, value} -> {normalize_key(key), value} end)

    unknown_keys = Map.keys(attrs) -- @allowed_fields

    cond do
      unknown_keys != [] ->
        {:error, {:unknown_fields, unknown_keys}}

      not is_binary(Map.get(attrs, :id)) or Map.get(attrs, :id) == "" ->
        {:error, :invalid_id}

      true ->
        validate_optional_fields(attrs)
    end
  end

  def new(_attrs), do: {:error, :invalid_attributes}

  defp normalize_key(key) when is_binary(key), do: Map.get(@field_names, key, key)
  defp normalize_key(key), do: key

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
