defmodule CreditEngine.ProposalStore do
  @moduledoc """
  Armazenamento das propostas cadastradas e do histórico de análises
  (incremento 11).

  É um `GenServer` supervisionado pela aplicação. Os dados ficam numa tabela
  DETS, que já vem com o Erlang/OTP e grava em arquivo: as propostas e o
  histórico continuam lá depois que a aplicação é reiniciada. O arquivo é
  definido em `config/config.exs` (`:armazenamento`, `:arquivo`).

  Cada registro guarda:

  - `proposta`: a struct `CreditEngine.Proposal` cadastrada;
  - `status`: o estado atual, `:nao_analisada` até a primeira análise;
  - `historico`: as análises concluídas, da mais antiga para a mais recente.

  Se o processo não responder, as funções devolvem
  `{:error, :armazenamento_indisponivel}` e registram a falha em log.
  """

  use GenServer

  require Logger

  alias CreditEngine.Proposal

  @type registro :: %{proposta: Proposal.t(), status: atom(), historico: [map()]}
  @type erro_armazenamento :: {:error, :armazenamento_indisponivel}

  # Inicialização

  @doc """
  Inicia o armazenamento. Opções, usadas nos testes:

  - `:name`: nome do processo (padrão: este módulo);
  - `:tabela`: nome da tabela DETS (padrão: este módulo);
  - `:arquivo`: caminho do arquivo (padrão: o da configuração).
  """
  def start_link(opcoes \\ []) do
    GenServer.start_link(__MODULE__, opcoes, name: Keyword.get(opcoes, :name, __MODULE__))
  end

  # Operações

  @doc "Cadastra a proposta. Um identificador já cadastrado é rejeitado sem sobrescrever."
  @spec cadastrar(GenServer.server(), Proposal.t()) ::
          :ok | {:error, :duplicado} | erro_armazenamento()
  def cadastrar(servidor \\ __MODULE__, %Proposal{} = proposta) do
    chamar(servidor, {:cadastrar, proposta})
  end

  @doc "Devolve o registro da proposta."
  @spec buscar(GenServer.server(), String.t()) ::
          {:ok, registro()} | {:error, :nao_encontrada} | erro_armazenamento()
  def buscar(servidor \\ __MODULE__, id), do: chamar(servidor, {:buscar, id})

  @doc "Lista o identificador e o estado atual de cada proposta, em ordem de identificador."
  @spec listar(GenServer.server()) :: {:ok, [map()]} | erro_armazenamento()
  def listar(servidor \\ __MODULE__), do: chamar(servidor, :listar)

  @doc "Devolve o histórico da proposta, da análise mais antiga para a mais recente."
  @spec historico(GenServer.server(), String.t()) ::
          {:ok, [map()]} | {:error, :nao_encontrada} | erro_armazenamento()
  def historico(servidor \\ __MODULE__, id) do
    with {:ok, registro} <- buscar(servidor, id), do: {:ok, registro.historico}
  end

  @doc """
  Registra uma análise concluída: acrescenta a entrada ao fim do histórico e
  atualiza o estado atual para o `status` da entrada, numa única operação.
  """
  @spec registrar_analise(GenServer.server(), String.t(), map()) ::
          {:ok, registro()} | {:error, :nao_encontrada} | erro_armazenamento()
  def registrar_analise(servidor \\ __MODULE__, id, %{status: _} = entrada) do
    chamar(servidor, {:registrar_analise, id, entrada})
  end

  @doc false
  # Apaga todos os registros. Usado só para deixar os testes independentes.
  def limpar(servidor \\ __MODULE__), do: chamar(servidor, :limpar)

  defp chamar(servidor, mensagem) do
    GenServer.call(servidor, mensagem)
  catch
    :exit, motivo ->
      Logger.error("Armazenamento de propostas indisponível: #{inspect(motivo)}")
      {:error, :armazenamento_indisponivel}
  end

  # Callbacks

  @impl true
  def init(opcoes) do
    # Garante que terminate/2 feche o arquivo quando o supervisor parar o processo.
    Process.flag(:trap_exit, true)

    tabela = Keyword.get(opcoes, :tabela, __MODULE__)
    arquivo = Keyword.get_lazy(opcoes, :arquivo, &arquivo_configurado/0)
    File.mkdir_p!(Path.dirname(arquivo))

    case :dets.open_file(tabela, file: String.to_charlist(arquivo), type: :set) do
      {:ok, tabela} -> {:ok, tabela}
      {:error, motivo} -> {:stop, {:arquivo_indisponivel, motivo}}
    end
  end

  @impl true
  def handle_call({:cadastrar, %Proposal{id: id} = proposta}, _de, tabela) do
    registro = %{proposta: proposta, status: :nao_analisada, historico: []}

    resposta =
      case :dets.insert_new(tabela, {id, registro}) do
        true -> gravar(tabela)
        false -> {:error, :duplicado}
        {:error, motivo} -> falha(motivo)
      end

    {:reply, resposta, tabela}
  end

  def handle_call({:buscar, id}, _de, tabela), do: {:reply, ler(tabela, id), tabela}

  def handle_call(:listar, _de, tabela) do
    resposta =
      case :dets.match_object(tabela, :_) do
        {:error, motivo} ->
          falha(motivo)

        objetos ->
          {:ok,
           objetos
           |> Enum.map(fn {id, registro} -> %{id: id, status: registro.status} end)
           |> Enum.sort_by(& &1.id)}
      end

    {:reply, resposta, tabela}
  end

  def handle_call({:registrar_analise, id, entrada}, _de, tabela) do
    resposta =
      with {:ok, registro} <- ler(tabela, id) do
        novo = %{registro | status: entrada.status, historico: registro.historico ++ [entrada]}

        case :dets.insert(tabela, {id, novo}) do
          :ok -> with :ok <- gravar(tabela), do: {:ok, novo}
          {:error, motivo} -> falha(motivo)
        end
      end

    {:reply, resposta, tabela}
  end

  def handle_call(:limpar, _de, tabela) do
    resposta =
      case :dets.delete_all_objects(tabela) do
        :ok -> gravar(tabela)
        {:error, motivo} -> falha(motivo)
      end

    {:reply, resposta, tabela}
  end

  @impl true
  def terminate(_motivo, tabela), do: :dets.close(tabela)

  defp ler(tabela, id) do
    case :dets.lookup(tabela, id) do
      [{^id, registro}] -> {:ok, registro}
      [] -> {:error, :nao_encontrada}
      {:error, motivo} -> falha(motivo)
    end
  end

  # Força a gravação no disco antes de responder que a operação foi concluída.
  defp gravar(tabela) do
    case :dets.sync(tabela) do
      :ok -> :ok
      {:error, motivo} -> falha(motivo)
    end
  end

  defp falha(motivo) do
    Logger.error("Falha no arquivo de propostas: #{inspect(motivo)}")
    {:error, :armazenamento_indisponivel}
  end

  defp arquivo_configurado do
    :credit_engine |> Application.fetch_env!(:armazenamento) |> Keyword.fetch!(:arquivo)
  end
end
