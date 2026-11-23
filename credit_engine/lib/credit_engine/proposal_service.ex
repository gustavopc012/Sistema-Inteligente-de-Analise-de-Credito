defmodule CreditEngine.ProposalService do
  @moduledoc """
  Operações do cadastro e do histórico de propostas (incremento 11).

  Liga o armazenamento (`CreditEngine.ProposalStore`) ao pipeline
  (`CreditEngine.analisar/1`). Não tem regra de negócio própria: a validação
  é a de `CreditEngine.Proposal.new/1` e a decisão é a do pipeline.
  """

  alias CreditEngine.{Decision, Proposal, ProposalStore}

  @campos_mapa [:applicant_data, :open_finance_data, :behavioral_data, :macroeconomic_data]

  # Campos lidos pelo pipeline. Dados que chegam por JSON têm chaves em texto;
  # só estes nomes são convertidos para átomo, e nenhum átomo novo é criado.
  @campos_conhecidos Map.new(
                       [
                         :taxa_inadimplencia_mercado,
                         :transacoes_noturnas,
                         :dispositivos_novos,
                         :tentativas_login_falhas,
                         :comprometimento_renda,
                         :atrasos_12m,
                         :tempo_relacionamento_anos
                       ],
                       &{Atom.to_string(&1), &1}
                     )

  @doc "Valida e cadastra a proposta. Devolve os dados cadastrados, com o estado inicial."
  @spec cadastrar(map()) :: {:ok, map()} | {:error, term()}
  def cadastrar(atributos) when is_map(atributos) do
    with {:ok, proposta} <- Proposal.new(normalizar(atributos)),
         :ok <- ProposalStore.cadastrar(proposta) do
      {:ok, detalhe(proposta, :nao_analisada)}
    end
  end

  def cadastrar(_atributos), do: {:error, :invalid_attributes}

  @doc "Consulta a proposta: identificador, estado atual e os quatro grupos de dados."
  @spec consultar(String.t()) :: {:ok, map()} | {:error, term()}
  def consultar(id) do
    with {:ok, registro} <- ProposalStore.buscar(id) do
      {:ok, detalhe(registro.proposta, registro.status)}
    end
  end

  @doc "Lista só o identificador e o estado atual de cada proposta."
  @spec listar() :: {:ok, [map()]} | {:error, term()}
  def listar, do: ProposalStore.listar()

  @doc "Histórico da proposta, da análise mais antiga para a mais recente."
  @spec historico(String.t()) :: {:ok, [map()]} | {:error, term()}
  def historico(id), do: ProposalStore.historico(id)

  @doc """
  Analisa a proposta cadastrada com os dados guardados, sem recebê-los de novo.

  Só uma decisão do pipeline gera entrada no histórico e muda o estado atual.
  Um erro do pipeline é devolvido como veio, sem alterar nada.
  """
  @spec analisar(String.t()) :: {:ok, map()} | {:error, term()}
  def analisar(id) do
    with {:ok, registro} <- ProposalStore.buscar(id),
         {:ok, %Decision{} = decisao} <-
           CreditEngine.analisar(Map.from_struct(registro.proposta)),
         entrada = entrada(id, decisao),
         {:ok, _registro} <- ProposalStore.registrar_analise(id, entrada) do
      {:ok, entrada}
    end
  end

  defp entrada(id, %Decision{} = decisao) do
    %{
      proposta_id: id,
      analisada_em: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      status: decisao.status,
      score: decisao.score,
      parecer: decisao.explanation
    }
  end

  defp detalhe(%Proposal{} = proposta, status) do
    proposta |> Map.from_struct() |> Map.put(:status, status)
  end

  # Converte para átomo as chaves conhecidas dentro dos quatro grupos de dados.
  defp normalizar(atributos) do
    Map.new(atributos, fn {chave, valor} ->
      if campo_mapa?(chave) and is_map(valor) do
        {chave, Map.new(valor, fn {k, v} -> {Map.get(@campos_conhecidos, k, k), v} end)}
      else
        {chave, valor}
      end
    end)
  end

  defp campo_mapa?(chave) when is_atom(chave), do: chave in @campos_mapa
  defp campo_mapa?(chave) when is_binary(chave), do: chave in Enum.map(@campos_mapa, &to_string/1)
  defp campo_mapa?(_chave), do: false
end
