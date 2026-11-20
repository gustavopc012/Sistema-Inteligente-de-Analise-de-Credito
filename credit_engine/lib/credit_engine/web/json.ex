defmodule CreditEngine.Web.JSON do
  @moduledoc """
  Codificador JSON mínimo para as respostas da interface web.

  O projeto não usa dependências externas, por isso este módulo cobre apenas
  os tipos que a API devolve: mapas, listas, textos, números, booleanos,
  `nil` e átomos.
  """

  @spec encode(term()) :: String.t()
  def encode(valor), do: valor |> do_encode() |> IO.iodata_to_binary()

  defp do_encode(nil), do: "null"
  defp do_encode(true), do: "true"
  defp do_encode(false), do: "false"
  defp do_encode(valor) when is_atom(valor), do: valor |> Atom.to_string() |> do_encode()
  defp do_encode(valor) when is_integer(valor), do: Integer.to_string(valor)
  defp do_encode(valor) when is_float(valor), do: Float.to_string(valor)
  defp do_encode(valor) when is_binary(valor), do: [?", escape(valor), ?"]

  defp do_encode(valor) when is_list(valor) do
    [?[, valor |> Enum.map(&do_encode/1) |> Enum.intersperse(?,), ?]]
  end

  defp do_encode(valor) when is_map(valor) do
    pares =
      valor
      |> Enum.sort_by(fn {chave, _} -> to_string(chave) end)
      |> Enum.map(fn {chave, v} -> [do_encode(to_string(chave)), ?:, do_encode(v)] end)
      |> Enum.intersperse(?,)

    [?{, pares, ?}]
  end

  defp escape(texto) do
    for <<c::utf8 <- texto>>, into: "" do
      case c do
        ?" -> "\\\""
        ?\\ -> "\\\\"
        ?\n -> "\\n"
        ?\r -> "\\r"
        ?\t -> "\\t"
        c when c < 0x20 -> "\\u" <> String.pad_leading(Integer.to_string(c, 16), 4, "0")
        c -> <<c::utf8>>
      end
    end
  end
end
