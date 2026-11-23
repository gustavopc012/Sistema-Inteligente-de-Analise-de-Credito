defmodule CreditEngine.ProposalServiceTest do
  # async: false porque usa o armazenamento da aplicação e o Circuit Breaker,
  # que são processos únicos.
  use ExUnit.Case, async: false

  alias CreditEngine.{ProposalService, ProposalStore}

  # Identificador único por teste: os testes não dependem uns dos outros.
  defp novo_id, do: "SERV-#{System.unique_integer([:positive])}"

  # Proposta como chega por JSON: chaves em texto. Perfil intermediário do
  # plan.md, com mercado normal e comportamento igual ao centro.
  defp atributos(id, alteracoes \\ %{}) do
    centro = Application.fetch_env!(:credit_engine, :anomalias)[:centro]

    %{
      "id" => id,
      "macroeconomic_data" => %{"taxa_inadimplencia_mercado" => 0.05},
      "behavioral_data" => Map.new(centro, fn {k, v} -> {Atom.to_string(k), v} end),
      "open_finance_data" => %{"comprometimento_renda" => 0.5, "atrasos_12m" => 1},
      "applicant_data" => %{"tempo_relacionamento_anos" => 2, "nome" => "Pessoa Sintética"}
    }
    |> Map.merge(alteracoes)
  end

  describe "cadastrar/1" do
    test "cadastra com estado inicial e converte só os campos conhecidos" do
      id = novo_id()
      assert {:ok, proposta} = ProposalService.cadastrar(atributos(id))

      assert proposta.id == id
      assert proposta.status == :nao_analisada
      assert proposta.open_finance_data == %{comprometimento_renda: 0.5, atrasos_12m: 1}
      # Chave desconhecida continua em texto: nenhum átomo novo é criado.
      assert proposta.applicant_data["nome"] == "Pessoa Sintética"
    end

    test "dados inválidos devolvem o erro da validação e não cadastram nada" do
      id = novo_id()

      assert ProposalService.cadastrar(atributos(id, %{"open_finance_data" => "texto"})) ==
               {:error, {:invalid_field, :open_finance_data}}

      assert ProposalService.cadastrar(%{"id" => ""}) == {:error, :invalid_id}
      assert ProposalService.cadastrar([]) == {:error, :invalid_attributes}
      assert ProposalService.consultar(id) == {:error, :nao_encontrada}
    end

    test "identificador duplicado é rejeitado" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id))

      assert ProposalService.cadastrar(atributos(id)) == {:error, :duplicado}
    end
  end

  describe "consultar/1, listar/0 e historico/1" do
    test "consulta traz os dados e o estado; a listagem, só id e estado" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id))

      assert {:ok, %{id: ^id, status: :nao_analisada, applicant_data: %{}}} =
               ProposalService.consultar(id)

      assert {:ok, lista} = ProposalService.listar()
      assert %{id: id, status: :nao_analisada} in lista
      assert Enum.all?(lista, &(Map.keys(&1) |> Enum.sort() == [:id, :status]))
    end

    test "histórico de proposta sem análise é vazio; de inexistente, não encontrada" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id))

      assert ProposalService.historico(id) == {:ok, []}
      assert ProposalService.historico("NAO-EXISTE") == {:error, :nao_encontrada}
    end
  end

  describe "analisar/1" do
    test "analisa com os dados cadastrados, igual ao pipeline, e registra no histórico" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id))
      {:ok, registro} = ProposalStore.buscar(id)
      {:ok, esperado} = CreditEngine.analisar(Map.from_struct(registro.proposta))

      assert {:ok, entrada} = ProposalService.analisar(id)

      assert entrada.proposta_id == id
      assert entrada.status == esperado.status
      assert entrada.score == esperado.score
      assert entrada.parecer == esperado.explanation
      assert {:ok, _data, 0} = DateTime.from_iso8601(entrada.analisada_em)
      assert {:ok, %{status: :analise_manual}} = ProposalService.consultar(id)
      assert ProposalService.historico(id) == {:ok, [entrada]}
    end

    test "reanálise acrescenta uma entrada e o estado reflete a mais recente" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id))

      {:ok, primeira} = ProposalService.analisar(id)
      {:ok, segunda} = ProposalService.analisar(id)

      assert ProposalService.historico(id) == {:ok, [primeira, segunda]}
    end

    test "recusa automática também é uma decisão e entra no histórico, sem score" do
      id = novo_id()
      taxa = Application.fetch_env!(:credit_engine, :circuit_breaker)[:limite_taxa_inadimplencia]

      {:ok, _} =
        ProposalService.cadastrar(
          atributos(id, %{"macroeconomic_data" => %{"taxa_inadimplencia_mercado" => taxa + 0.01}})
        )

      assert {:ok, %{status: :recusa_automatica, score: nil, parecer: nil}} =
               ProposalService.analisar(id)

      assert {:ok, %{status: :recusa_automatica}} = ProposalService.consultar(id)
    end

    test "falha sem decisão não muda o estado nem o histórico" do
      id = novo_id()
      {:ok, _} = ProposalService.cadastrar(atributos(id, %{"open_finance_data" => %{}}))

      assert ProposalService.analisar(id) == {:error, {:dado_ausente, :comprometimento_renda}}
      assert {:ok, %{status: :nao_analisada}} = ProposalService.consultar(id)
      assert ProposalService.historico(id) == {:ok, []}
    end

    test "proposta inexistente devolve não encontrada" do
      assert ProposalService.analisar("NAO-EXISTE") == {:error, :nao_encontrada}
    end
  end
end
