defmodule CreditEngine.Web.JSONDecoderTest do
  use ExUnit.Case, async: true

  alias CreditEngine.Web.{JSON, JSONDecoder}

  test "decodifica os tipos simples" do
    assert JSONDecoder.decode("null") == {:ok, nil}
    assert JSONDecoder.decode("true") == {:ok, true}
    assert JSONDecoder.decode("false") == {:ok, false}
    assert JSONDecoder.decode(~s("texto")) == {:ok, "texto"}
  end

  test "decodifica números inteiros, negativos, decimais e com expoente" do
    assert JSONDecoder.decode("0") == {:ok, 0}
    assert JSONDecoder.decode("-12") == {:ok, -12}
    assert JSONDecoder.decode("0.05") == {:ok, 0.05}
    assert JSONDecoder.decode("-1.5e2") == {:ok, -150.0}
    assert JSONDecoder.decode("1E3") == {:ok, 1000.0}
  end

  test "decodifica objetos e arrays aninhados, com espaços" do
    assert JSONDecoder.decode(~s( { "a" : [1, {"b": null}, []], "c": {} } )) ==
             {:ok, %{"a" => [1, %{"b" => nil}, []], "c" => %{}}}
  end

  test "decodifica escapes e Unicode, inclusive pares substitutos" do
    assert JSONDecoder.decode(~S("aspas \" barra \\ / \n \t")) ==
             {:ok, "aspas \" barra \\ / \n \t"}

    assert JSONDecoder.decode(~S("ação é 😀")) == {:ok, "ação é 😀"}
  end

  test "as chaves ficam em texto: nenhum átomo é criado" do
    chave = "chave_que_nao_existe_como_atomo_#{System.unique_integer([:positive])}"

    assert {:ok, %{^chave => 1}} = JSONDecoder.decode(~s({"#{chave}": 1}))
    assert_raise ArgumentError, fn -> String.to_existing_atom(chave) end
  end

  test "rejeita JSON malformado e conteúdo sobrando" do
    for invalido <- [
          "",
          "{",
          "[1,]",
          ~s({"a":1,}),
          ~s({"a" 1}),
          ~s({a: 1}),
          "01",
          "1.",
          "tru",
          ~s("sem fim),
          ~s("\\x"),
          ~s("\\ud83d"),
          "{} {}",
          "[1] 2",
          "nul",
          "1e400"
        ] do
      assert JSONDecoder.decode(invalido) == {:error, :json_invalido},
             "aceitou: #{inspect(invalido)}"
    end

    assert JSONDecoder.decode(nil) == {:error, :json_invalido}
  end

  test "lê de volta o que o codificador existente gera" do
    valor = %{
      "status" => "recusado",
      "fatores" => [%{"campo" => "atrasos_12m", "contribuicao" => 2.4}]
    }

    assert JSONDecoder.decode(JSON.encode(valor)) == {:ok, valor}
  end
end
