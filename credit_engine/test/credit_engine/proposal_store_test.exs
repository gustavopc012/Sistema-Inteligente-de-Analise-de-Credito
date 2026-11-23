defmodule CreditEngine.ProposalStoreTest do
  use ExUnit.Case, async: true

  alias CreditEngine.{Proposal, ProposalStore}

  # Cada teste usa o próprio processo, tabela e arquivo, separados do
  # armazenamento da aplicação.
  setup do
    n = System.unique_integer([:positive])
    pasta = Path.join(System.tmp_dir!(), "credit_engine_store_#{n}")
    File.rm_rf!(pasta)
    on_exit(fn -> File.rm_rf!(pasta) end)

    opcoes = [
      name: nil,
      tabela: :"proposal_store_teste_#{n}",
      arquivo: Path.join(pasta, "p.dets")
    ]

    {:ok, opcoes: opcoes, servidor: iniciar(opcoes)}
  end

  defp iniciar(opcoes) do
    start_supervised!({ProposalStore, opcoes}, id: make_ref(), restart: :temporary)
  end

  defp proposta(id), do: %Proposal{id: id, applicant_data: %{tempo_relacionamento_anos: 2}}
  defp entrada(id, status), do: %{proposta_id: id, status: status, score: nil, parecer: nil}

  test "uma proposta cadastrada começa sem análise e com histórico vazio", %{servidor: s} do
    assert :ok = ProposalStore.cadastrar(s, proposta("P-1"))

    assert {:ok, %{proposta: %Proposal{id: "P-1"}, status: :nao_analisada, historico: []}} =
             ProposalStore.buscar(s, "P-1")

    assert ProposalStore.historico(s, "P-1") == {:ok, []}
  end

  test "identificador duplicado é rejeitado sem sobrescrever", %{servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("P-1"))
    outra = %Proposal{id: "P-1", applicant_data: %{tempo_relacionamento_anos: 99}}

    assert ProposalStore.cadastrar(s, outra) == {:error, :duplicado}
    assert {:ok, %{proposta: proposta}} = ProposalStore.buscar(s, "P-1")
    assert proposta.applicant_data.tempo_relacionamento_anos == 2
  end

  test "a comparação do identificador é exata", %{servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("abc"))

    assert :ok = ProposalStore.cadastrar(s, proposta("ABC"))
    assert ProposalStore.buscar(s, "Abc") == {:error, :nao_encontrada}
  end

  test "proposta inexistente devolve nao_encontrada", %{servidor: s} do
    assert ProposalStore.buscar(s, "X") == {:error, :nao_encontrada}
    assert ProposalStore.historico(s, "X") == {:error, :nao_encontrada}

    assert ProposalStore.registrar_analise(s, "X", entrada("X", :aprovado)) ==
             {:error, :nao_encontrada}
  end

  test "a listagem traz só identificador e estado, em ordem de identificador", %{servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("B"))
    :ok = ProposalStore.cadastrar(s, proposta("A"))

    assert ProposalStore.listar(s) ==
             {:ok, [%{id: "A", status: :nao_analisada}, %{id: "B", status: :nao_analisada}]}
  end

  test "registrar análise atualiza o estado e preserva as anteriores, em ordem", %{servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("P-1"))

    {:ok, _} = ProposalStore.registrar_analise(s, "P-1", entrada("P-1", :analise_manual))
    assert {:ok, registro} = ProposalStore.registrar_analise(s, "P-1", entrada("P-1", :aprovado))

    assert registro.status == :aprovado
    assert Enum.map(registro.historico, & &1.status) == [:analise_manual, :aprovado]

    assert {:ok, [%{status: :analise_manual}, %{status: :aprovado}]} =
             ProposalStore.historico(s, "P-1")
  end

  test "análises de uma proposta não afetam outra", %{servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("A"))
    :ok = ProposalStore.cadastrar(s, proposta("B"))
    {:ok, _} = ProposalStore.registrar_analise(s, "A", entrada("A", :recusado))

    assert {:ok, %{status: :nao_analisada, historico: []}} = ProposalStore.buscar(s, "B")
  end

  test "os dados continuam lá depois que o processo é reiniciado", %{opcoes: opcoes, servidor: s} do
    :ok = ProposalStore.cadastrar(s, proposta("P-1"))
    {:ok, _} = ProposalStore.registrar_analise(s, "P-1", entrada("P-1", :recusado))

    :ok = GenServer.stop(s)
    novo = iniciar(opcoes)

    assert {:ok, %{status: :recusado, historico: [%{status: :recusado}]}} =
             ProposalStore.buscar(novo, "P-1")
  end

  test "armazenamento parado devolve indisponível, sem simular sucesso", %{servidor: s} do
    :ok = GenServer.stop(s)

    capture = fn ->
      assert ProposalStore.listar(s) == {:error, :armazenamento_indisponivel}
      assert ProposalStore.cadastrar(s, proposta("P-1")) == {:error, :armazenamento_indisponivel}
    end

    assert ExUnit.CaptureLog.capture_log(capture) =~ "indisponível"
  end
end
