defmodule CreditEngine.Web.JSONDecoder do
  @moduledoc """
  Decodificador JSON mínimo para o corpo das requisições (incremento 11).

  O projeto não usa dependências externas, e o Elixir 1.14 não traz um
  decodificador JSON, por isso ele é implementado aqui. Cobre objetos,
  arrays, textos (com escapes e `\\u`), números, booleanos e `null`.

  As chaves dos objetos ficam em texto: nenhum átomo é criado a partir de
  dados externos. Qualquer JSON malformado, ou com conteúdo sobrando depois
  do valor, devolve `{:error, :json_invalido}`.
  """

  @spec decode(binary()) :: {:ok, term()} | {:error, :json_invalido}
  def decode(texto) when is_binary(texto) do
    {valor, resto} = valor(pular(texto))

    case pular(resto) do
      "" -> {:ok, valor}
      _sobra -> {:error, :json_invalido}
    end
  catch
    :throw, :json_invalido -> {:error, :json_invalido}
  end

  def decode(_texto), do: {:error, :json_invalido}

  defp invalido, do: throw(:json_invalido)

  defp pular(<<c, resto::binary>>) when c in [?\s, ?\t, ?\n, ?\r], do: pular(resto)
  defp pular(resto), do: resto

  defp valor("{" <> resto), do: objeto(pular(resto), %{})
  defp valor("[" <> resto), do: lista(pular(resto), [])
  defp valor("\"" <> resto), do: texto(resto, [])
  defp valor("true" <> resto), do: {true, resto}
  defp valor("false" <> resto), do: {false, resto}
  defp valor("null" <> resto), do: {nil, resto}
  defp valor(<<c, _::binary>> = resto) when c == ?- or c in ?0..?9, do: numero(resto)
  defp valor(_resto), do: invalido()

  # Objetos

  defp objeto("}" <> resto, acc) when map_size(acc) == 0, do: {acc, resto}

  defp objeto("\"" <> resto, acc) do
    {chave, resto} = texto(resto, [])

    resto =
      case pular(resto) do
        ":" <> resto -> pular(resto)
        _ -> invalido()
      end

    {valor, resto} = valor(resto)
    acc = Map.put(acc, chave, valor)

    case pular(resto) do
      "," <> resto -> objeto_proxima_chave(pular(resto), acc)
      "}" <> resto -> {acc, resto}
      _ -> invalido()
    end
  end

  defp objeto(_resto, _acc), do: invalido()

  defp objeto_proxima_chave("\"" <> _ = resto, acc), do: objeto(resto, acc)
  defp objeto_proxima_chave(_resto, _acc), do: invalido()

  # Arrays

  defp lista("]" <> resto, []), do: {[], resto}

  defp lista(resto, acc) do
    {valor, resto} = valor(resto)
    acc = [valor | acc]

    case pular(resto) do
      "," <> resto -> lista(pular(resto), acc)
      "]" <> resto -> {Enum.reverse(acc), resto}
      _ -> invalido()
    end
  end

  # Textos

  defp texto("\"" <> resto, acc), do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), resto}

  defp texto("\\" <> <<c, resto::binary>>, acc) do
    case c do
      ?" -> texto(resto, ["\"" | acc])
      ?\\ -> texto(resto, ["\\" | acc])
      ?/ -> texto(resto, ["/" | acc])
      ?b -> texto(resto, ["\b" | acc])
      ?f -> texto(resto, ["\f" | acc])
      ?n -> texto(resto, ["\n" | acc])
      ?r -> texto(resto, ["\r" | acc])
      ?t -> texto(resto, ["\t" | acc])
      ?u -> unicode(resto, acc)
      _ -> invalido()
    end
  end

  defp texto(<<c::utf8, resto::binary>>, acc) when c >= 0x20,
    do: texto(resto, [<<c::utf8>> | acc])

  defp texto(_resto, _acc), do: invalido()

  defp unicode(resto, acc) do
    {codigo, resto} = hex4(resto)

    cond do
      codigo in 0xD800..0xDBFF ->
        case resto do
          "\\u" <> resto ->
            {baixo, resto} = hex4(resto)
            if baixo not in 0xDC00..0xDFFF, do: invalido()
            combinado = 0x10000 + Bitwise.bsl(codigo - 0xD800, 10) + (baixo - 0xDC00)
            texto(resto, [<<combinado::utf8>> | acc])

          _ ->
            invalido()
        end

      codigo in 0xDC00..0xDFFF ->
        invalido()

      true ->
        texto(resto, [<<codigo::utf8>> | acc])
    end
  end

  defp hex4(<<digitos::binary-size(4), resto::binary>>) do
    if digitos =~ ~r/\A[0-9a-fA-F]{4}\z/ do
      {String.to_integer(digitos, 16), resto}
    else
      invalido()
    end
  end

  defp hex4(_resto), do: invalido()

  # Números

  defp numero(resto) do
    # Regex escrita aqui, e não num atributo do módulo: no Elixir 1.19+ com
    # OTP 28+, regex em atributo de módulo gera aviso de compilação.
    case Regex.run(~r/\A-?(?:0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/, resto) do
      [literal] ->
        {String.to_integer(literal), corte(resto, literal)}

      [literal | _partes] ->
        {decimal(literal), corte(resto, literal)}

      nil ->
        invalido()
    end
  end

  defp decimal(literal) do
    # Float.parse não aceita expoente sem parte decimal ("1e5"), por isso ela é completada.
    normalizado = String.replace(literal, ~r/\A(-?[0-9]+)([eE])/, "\\1.0\\2")

    case Float.parse(normalizado) do
      {valor, ""} -> valor
      _ -> invalido()
    end
  rescue
    ArgumentError -> invalido()
  end

  defp corte(resto, literal),
    do: binary_part(resto, byte_size(literal), byte_size(resto) - byte_size(literal))
end
