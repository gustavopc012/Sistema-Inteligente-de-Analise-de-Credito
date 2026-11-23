import Config

# Valores de demonstração do MVP (plan.md, seção 7).
# Não são calibrados com dados reais. Para alterar um valor, mude aqui,
# nunca no código ou nos testes.

# T2 — Circuit Breaker: bloqueia propostas quando a taxa de inadimplência
# do mercado (macroeconomic_data.taxa_inadimplencia_mercado) passa do limite.
config :credit_engine, :circuit_breaker, limite_taxa_inadimplencia: 0.08

# T3 — Detecção de anomalias: distância euclidiana entre os campos de
# behavioral_data e o centro de referência.
config :credit_engine, :anomalias,
  centro: %{
    transacoes_noturnas: 2,
    dispositivos_novos: 0,
    tentativas_login_falhas: 1
  },
  distancia_maxima: 3.0

# T4 e T6 — Score de risco e parecer: z = intercepto + soma(peso * valor).
# comprometimento_renda e atrasos_12m vêm de open_finance_data;
# tempo_relacionamento_anos vem de applicant_data.
config :credit_engine, :score,
  intercepto: -2.0,
  pesos: %{
    comprometimento_renda: 3.0,
    atrasos_12m: 0.8,
    tempo_relacionamento_anos: -0.3
  }

# T5 — Limiares: abaixo de aprovado_abaixo_de é aprovado; acima de
# recusado_acima_de é recusado; entre os dois (inclusive) é análise manual.
config :credit_engine, :limiares,
  aprovado_abaixo_de: 0.30,
  recusado_acima_de: 0.60

# Incremento 11 — Arquivo DETS onde ficam as propostas cadastradas e o
# histórico de análises. Os testes usam um arquivo separado.
config :credit_engine, :armazenamento,
  arquivo:
    if(config_env() == :test, do: "tmp/test/propostas.dets", else: "data/propostas.dets")
