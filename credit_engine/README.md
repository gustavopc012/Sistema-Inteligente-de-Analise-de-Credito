# CreditEngine — Sistema Inteligente de Análise de Crédito

Projeto Elixir (Mix) com o MVP do sistema. A proposta passa por cinco etapas, nesta ordem:

**Circuit Breaker → detecção de anomalias → score de risco → limiares de decisão → parecer explicável**

Os parâmetros de cada etapa ficam em `config/config.exs`. São valores de demonstração, não calibrados com dados reais (`plan.md`, seção 7).

## Requisitos

- Elixir 1.14 ou superior compatível com `~> 1.14`
- Erlang/OTP compatível com a versão instalada do Elixir

## Executar

Na pasta `credit_engine/`:

```bash
mix compile
mix test
```

Para abrir o console interativo:

```bash
iex -S mix
```

O projeto não possui dependências externas.

## Interface web

Além do `iex`, a demonstração pode ser feita pelo navegador. Na pasta `credit_engine/`:

```bash
mix credit_engine.web
```

Depois, abra http://localhost:4000. Para encerrar, use Ctrl+C duas vezes. Se a porta 4000 estiver ocupada, use outra: `mix credit_engine.web 4001`.

Também dá para abrir a interface de dentro do `iex -S mix`, com `CreditEngine.Web.start()`. Assim, o `iex` e o navegador usam o mesmo Circuit Breaker, e o contador de bloqueios é o mesmo nos dois.

A página tem:

- botões para os cinco cenários desta seção de demonstração, que preenchem a proposta e analisam na hora;
- o formulário da proposta, que também aceita valores livres (campo vazio vira dado ausente; texto vira dado inválido);
- as cinco etapas do pipeline, marcando as que passaram, a que bloqueou e as que não foram executadas;
- a decisão, a régua do score com os limiares e o parecer com os fatores que aumentam e que reduzem o risco;
- o retorno de `CreditEngine.analisar/1` em Elixir.

A interface usa o servidor HTTP que já vem com o Erlang/OTP (`:httpd`), sem Phoenix nem dependências externas, e só aceita conexões do próprio computador. Ela não tem regra de negócio: toda decisão vem de `CreditEngine.analisar/1`.

## Demonstração

Os comandos abaixo mostram, no `iex`, os cinco cenários do critério de pronto (`plan.md`, seção 8). Os mesmos cenários são testados em `test/credit_engine/cenarios_test.exs`.

Abra o console com `iex -S mix` e crie uma proposta base. Ela tem mercado normalizado (taxa de 5%, abaixo do limite de 8%), comportamento igual ao padrão e o perfil de bom pagador:

```elixir
base = %{
  id: "DEMO-001",
  macroeconomic_data: %{taxa_inadimplencia_mercado: 0.05},
  behavioral_data: %{transacoes_noturnas: 2, dispositivos_novos: 0, tentativas_login_falhas: 1},
  open_finance_data: %{comprometimento_renda: 0.2, atrasos_12m: 0},
  applicant_data: %{tempo_relacionamento_anos: 5}
}
```

### 1. Recusa automática por colapso de mercado

A taxa de inadimplência do mercado passa do limite (10% > 8%). O Circuit Breaker bloqueia antes das outras etapas, então não há score nem parecer.

```elixir
CreditEngine.analisar(put_in(base.macroeconomic_data.taxa_inadimplencia_mercado, 0.10))
```

```text
{:ok,
 %CreditEngine.Decision{
   status: :recusa_automatica,
   score: nil,
   explanation: nil
 }}
```

### 2. Recusa de segurança por suspeita de fraude

Dez transações noturnas deixam o comportamento a uma distância 8,0 do centro, acima da máxima de 3,0. A proposta é recusada antes do score.

```elixir
CreditEngine.analisar(put_in(base.behavioral_data.transacoes_noturnas, 10))
```

```text
{:ok,
 %CreditEngine.Decision{status: :recusa_seguranca, score: nil, explanation: nil}}
```

### 3. Crédito aprovado, com parecer

Bom pagador: comprometimento de renda 0,2, nenhum atraso e 5 anos de relacionamento. A probabilidade de inadimplência fica abaixo de 0,30.

```elixir
CreditEngine.analisar(base)
```

```text
{:ok,
 %CreditEngine.Decision{
   status: :aprovado,
   score: 0.05215356307841774,
   explanation: %{
     fatores_negativos: [
       %{campo: :comprometimento_renda, contribuicao: 0.6000000000000001}
     ],
     fatores_positivos: [
       %{campo: :tempo_relacionamento_anos, contribuicao: -1.5}
     ]
   }
 }}
```

Os atrasos não aparecem no parecer porque, com zero atrasos, a contribuição é zero.

### 4. Crédito recusado pelo score, com parecer

Mau pagador: comprometimento de renda 0,8, três atrasos e 1 ano de relacionamento. A probabilidade fica acima de 0,60.

```elixir
CreditEngine.analisar(%{base | open_finance_data: %{comprometimento_renda: 0.8, atrasos_12m: 3}, applicant_data: %{tempo_relacionamento_anos: 1}})
```

```text
{:ok,
 %CreditEngine.Decision{
   status: :recusado,
   score: 0.9241418199787566,
   explanation: %{
     fatores_negativos: [
       %{campo: :atrasos_12m, contribuicao: 2.4000000000000004},
       %{campo: :comprometimento_renda, contribuicao: 2.4000000000000004}
     ],
     fatores_positivos: [
       %{campo: :tempo_relacionamento_anos, contribuicao: -0.3}
     ]
   }
 }}
```

Neste perfil, atrasos (0,8 × 3) e comprometimento de renda (3,0 × 0,8) pesam o mesmo.

### 5. Análise manual, com parecer

Perfil intermediário: comprometimento de renda 0,5, um atraso e 2 anos de relacionamento. A probabilidade fica entre 0,30 e 0,60.

```elixir
CreditEngine.analisar(%{base | open_finance_data: %{comprometimento_renda: 0.5, atrasos_12m: 1}, applicant_data: %{tempo_relacionamento_anos: 2}})
```

```text
{:ok,
 %CreditEngine.Decision{
   status: :analise_manual,
   score: 0.4255574831883409,
   explanation: %{
     fatores_negativos: [
       %{campo: :comprometimento_renda, contribuicao: 1.5},
       %{campo: :atrasos_12m, contribuicao: 0.8}
     ],
     fatores_positivos: [
       %{campo: :tempo_relacionamento_anos, contribuicao: -0.6}
     ]
   }
 }}
```

### Extras

Estado do Circuit Breaker, que é um processo OTP supervisionado. O contador mostra quantas propostas ele bloqueou desde que a aplicação subiu (aqui, 1, do cenário 1):

```elixir
CreditEngine.Safety.CircuitBreaker.status()
```

```text
%{bloqueios: 1, limite: 0.08}
```

Entrada inválida devolve um erro, e não uma decisão:

```elixir
CreditEngine.analisar(%{base | open_finance_data: %{comprometimento_renda: 1.5, atrasos_12m: 0}})
```

```text
{:error, {:dado_invalido, :comprometimento_renda}}
```

## Estrutura

```text
credit_engine/
├── lib/
│   ├── credit_engine.ex                  # analisar/1: pipeline completo (T7)
│   ├── credit_engine/
│   │   ├── application.ex                # supervisor OTP
│   │   ├── proposal.ex                   # proposta e validação de entrada
│   │   ├── decision.ex                   # decisão final (status, score, parecer)
│   │   ├── safety/circuit_breaker.ex     # Circuit Breaker (T2)
│   │   ├── ml/unsupervised.ex            # detecção de anomalias (T3)
│   │   ├── ml/supervised.ex              # score de risco (T4)
│   │   ├── decision/thresholds.ex        # limiares de decisão (T5)
│   │   ├── compliance/xai.ex             # parecer explicável (T6)
│   │   ├── web.ex                        # interface web: iniciar e parar (T10)
│   │   └── web/                          # rotas, API e JSON da interface (T10)
│   └── mix/tasks/credit_engine.web.ex    # comando mix credit_engine.web (T10)
├── priv/
│   └── static/index.html                 # página da interface web (T10)
├── config/
│   └── config.exs                        # valores de demonstração (plan.md, seção 7)
├── test/
│   ├── test_helper.exs
│   ├── credit_engine_test.exs
│   └── credit_engine/
│       ├── cenarios_test.exs             # cinco cenários de ponta a ponta (T8)
│       ├── pipeline_test.exs             # pipeline (T7)
│       ├── web_test.exs, web/            # interface web (T10)
│       └── ...                           # um arquivo de teste por módulo
├── .formatter.exs
├── .gitignore
└── mix.exs
```

## Diretrizes

- Utilizar dados sintéticos nos testes.
- Não inserir dados pessoais reais no repositório.
- Não versionar senhas, tokens ou chaves.
- Alterar parâmetros somente em `config/config.exs`, nunca no código ou nos testes.
- Não declarar testes como aprovados sem executá-los.
