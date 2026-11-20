defmodule CreditEngine.Web.API do
  @moduledoc """
  Respostas da API da interface web.

  Converte os parâmetros do formulário em atributos de proposta, chama
  `CreditEngine.analisar/1` e monta a resposta. Não contém regra de negócio:
  toda decisão vem do pipeline.
  """

  alias CreditEngine.Decision
  alias CreditEngine.ML.Unsupervised
  alias CreditEngine.Proposal
  alias CreditEngine.Safety.CircuitBreaker

  @campos [
    {:macroeconomic_data, :taxa_inadimplencia_mercado},
    {:behavioral_data, :transacoes_noturnas},
    {:behavioral_data, :dispositivos_novos},
    {:behavioral_data, :tentativas_login_falhas},
    {:open_finance_data, :comprometimento_renda},
    {:open_finance_data, :atrasos_12m},
    {:applicant_data, :tempo_relacionamento_anos}
  ]

  @etapas [:circuit_breaker, :anomalias, :score, :limiares, :parecer]

  @doc """
  Analisa a proposta descrita pelos parâmetros do formulário.

  Campo vazio ou ausente vira `nil` (dado ausente). Número com vírgula ou
  ponto é convertido; qualquer outro texto é repassado como está, e o
  pipeline devolve dado inválido.
  """
  @spec analisar(%{optional(String.t()) => String.t()}) :: {pos_integer(), map()}
  def analisar(parametros) do
    atributos = atributos(parametros)
    resultado = CreditEngine.analisar(atributos)
    elixir = inspect(resultado, pretty: true, width: 70)

    case resultado do
      {:ok, %Decision{} = decisao} ->
        {200,
         %{
           ok: true,
           decisao: Map.from_struct(decisao),
           etapas: etapas(decisao.status),
           distancia: distancia(atributos, decisao.status),
           circuit_breaker: CircuitBreaker.status(),
           parametros: parametros_config(),
           elixir: elixir
         }}

      {:error, motivo} ->
        {422,
         %{
           ok: false,
           erro: %{mensagem: mensagem(motivo), campo: campo(motivo)},
           circuit_breaker: CircuitBreaker.status(),
           parametros: parametros_config(),
           elixir: elixir
         }}
    end
  end

  @doc "Estado do Circuit Breaker e parâmetros da configuração."
  @spec status() :: {pos_integer(), map()}
  def status do
    {200, %{circuit_breaker: CircuitBreaker.status(), parametros: parametros_config()}}
  end

  @doc false
  def atributos(parametros) do
    dados =
      Enum.reduce(@campos, %{}, fn {mapa, campo}, acc ->
        valor = parametros |> Map.get(Atom.to_string(campo)) |> converter()
        Map.update(acc, mapa, %{campo => valor}, &Map.put(&1, campo, valor))
      end)

    Map.put(dados, :id, Map.get(parametros, "id", ""))
  end

  defp converter(nil), do: nil

  defp converter(texto) do
    texto = String.trim(texto)

    cond do
      texto == "" -> nil
      numero = numero(String.replace(texto, ",", ".")) -> numero
      true -> texto
    end
  end

  defp numero(texto) do
    case Integer.parse(texto) do
      {inteiro, ""} ->
        inteiro

      _ ->
        case Float.parse(texto) do
          {decimal, ""} -> decimal
          _ -> nil
        end
    end
  end

  # Quais etapas rodaram, a partir do status da decisão (ordem fixa do pipeline).
  defp etapas(status) do
    resultados =
      case status do
        :recusa_automatica -> [:bloqueou]
        :recusa_seguranca -> [:passou, :bloqueou]
        _ -> List.duplicate(:passou, length(@etapas))
      end

    resultados =
      resultados ++ List.duplicate(:nao_executada, length(@etapas) - length(resultados))

    Enum.zip_with(@etapas, resultados, fn etapa, resultado ->
      %{etapa: etapa, resultado: resultado}
    end)
  end

  # Distância até o centro, só quando a detecção de anomalias rodou.
  defp distancia(_atributos, :recusa_automatica), do: nil

  defp distancia(atributos, _status) do
    with {:ok, proposal} <- Proposal.new(atributos),
         {:ok, distancia} <- Unsupervised.distancia(proposal) do
      distancia
    else
      _ -> nil
    end
  end

  defp parametros_config do
    circuit_breaker = Application.fetch_env!(:credit_engine, :circuit_breaker)
    anomalias = Application.fetch_env!(:credit_engine, :anomalias)
    limiares = Application.fetch_env!(:credit_engine, :limiares)

    %{
      limite_taxa_inadimplencia: circuit_breaker[:limite_taxa_inadimplencia],
      distancia_maxima: anomalias[:distancia_maxima],
      aprovado_abaixo_de: limiares[:aprovado_abaixo_de],
      recusado_acima_de: limiares[:recusado_acima_de]
    }
  end

  defp mensagem({:dado_ausente, campo}), do: "Campo obrigatório ausente: #{campo}."
  defp mensagem({:dado_invalido, campo}), do: "Valor inválido no campo #{campo}."
  defp mensagem(:invalid_id), do: "O identificador da proposta não pode ficar vazio."
  defp mensagem(motivo), do: "Entrada inválida: #{inspect(motivo)}."

  defp campo({_tipo, campo}) when is_atom(campo), do: campo
  defp campo(:invalid_id), do: :id
  defp campo(_motivo), do: nil
end
