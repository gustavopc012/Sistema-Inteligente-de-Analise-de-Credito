defmodule CreditEngine.Web.JSONTest do
  use ExUnit.Case, async: true

  alias CreditEngine.Web.JSON

  test "codifica os tipos simples" do
    assert JSON.encode(nil) == "null"
    assert JSON.encode(true) == "true"
    assert JSON.encode(false) == "false"
    assert JSON.encode(42) == "42"
    assert JSON.encode(0.5) == "0.5"
    assert JSON.encode(:aprovado) == ~s("aprovado")
  end

  test "escapa aspas, barras e quebras de linha e mantém acentos" do
    assert JSON.encode(~s(a "b" \\ c\nção)) == ~s("a \\"b\\" \\\\ c\\nção")
  end

  test "codifica listas e mapas aninhados, com chaves em ordem" do
    valor = %{status: :recusado, fatores: [%{campo: :atrasos_12m, contribuicao: 2.4}], score: nil}

    assert JSON.encode(valor) ==
             ~s({"fatores":[{"campo":"atrasos_12m","contribuicao":2.4}],"score":null,"status":"recusado"})
  end
end
