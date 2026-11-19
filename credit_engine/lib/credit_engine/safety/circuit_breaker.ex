defmodule CreditEngine.Safety.CircuitBreaker do
  @moduledoc """
  Circuit Breaker do sistema (T2).

  Recusa a proposta quando a taxa de inadimplência do mercado
  (`macroeconomic_data.taxa_inadimplencia_mercado`) passa do limite
  configurado em `config/config.exs` (`:circuit_breaker`).

  É um GenServer supervisionado pela `CreditEngine.Application`. O estado
  guarda o limite em uso e quantas propostas já foram bloqueadas.

  Taxa igual ao limite não bloqueia: o plano diz que bloqueia "acima" dele.
  """

  use GenServer

  alias CreditEngine.Proposal

  @campo :taxa_inadimplencia_mercado

  @type erro :: :crise_sistemica | {:dado_ausente, atom()} | {:dado_invalido, atom()}

  ## API

  @doc """
  Inicia o Circuit Breaker lendo o limite da configuração.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Avalia a proposta contra o limite de inadimplência do mercado.
  """
  @spec evaluate(Proposal.t()) :: {:ok, Proposal.t()} | {:error, erro()}
  def evaluate(%Proposal{} = proposal) do
    GenServer.call(__MODULE__, {:evaluate, proposal})
  end

  @doc """
  Devolve o limite em uso e quantas propostas foram bloqueadas.
  """
  @spec status() :: %{limite: number(), bloqueios: non_neg_integer()}
  def status do
    GenServer.call(__MODULE__, :status)
  end

  ## Callbacks

  @impl true
  def init(:ok) do
    config = Application.fetch_env!(:credit_engine, :circuit_breaker)
    {:ok, %{limite: Keyword.fetch!(config, :limite_taxa_inadimplencia), bloqueios: 0}}
  end

  @impl true
  def handle_call({:evaluate, proposal}, _from, state) do
    case taxa_inadimplencia(proposal) do
      {:ok, taxa} when taxa > state.limite ->
        {:reply, {:error, :crise_sistemica}, %{state | bloqueios: state.bloqueios + 1}}

      {:ok, _taxa} ->
        {:reply, {:ok, proposal}, state}

      {:error, _motivo} = erro ->
        {:reply, erro, state}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, Map.take(state, [:limite, :bloqueios]), state}
  end

  ## Funções privadas

  defp taxa_inadimplencia(%Proposal{macroeconomic_data: dados}) when is_map(dados) do
    case Map.get(dados, @campo) do
      nil -> {:error, {:dado_ausente, @campo}}
      taxa when is_number(taxa) and taxa >= 0 and taxa <= 1 -> {:ok, taxa}
      _outro -> {:error, {:dado_invalido, @campo}}
    end
  end

  defp taxa_inadimplencia(%Proposal{}), do: {:error, {:dado_ausente, @campo}}
end
