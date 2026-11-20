## Plano técnico do MVP

**Projeto:** Sistema Inteligente de Análise de Crédito  
**Equipe:** Omicron  
**Definido em:** 17/11/2026  
**Prazo:** escopo fecha em 19/11/2026

Este documento corresponde à Etapa 2 do `docs/fluxo-sdd.md` e responde às decisões DP01 (escopo do MVP) e DP02 (tecnologias) de `docs/decisoes-pendentes.md`. As tarefas que implementam este plano estão em `tasks.md`.

---

## 1. Objetivo

Demonstrar o fluxo do diagrama de sequência funcionando de ponta a ponta, com dados sintéticos:

**proposta → Circuit Breaker → detecção de anomalias → score de risco → limiares → parecer explicável**

O foco é mostrar os conceitos de CLP em Elixir (subprogramas, structs, pattern matching, `{:ok, _} | {:error, _}`, `with` e processos OTP), e não reproduzir modelos de produção.

## 2. Escopo

### 2.1. Incluído

- Validação da proposta (incremento 1, já concluído).
- Circuit Breaker baseado na taxa de inadimplência do mercado.
- Detecção de anomalias comportamentais por distância euclidiana.
- Score de risco por fórmula logística.
- Classificação por limiares: aprovado, análise manual ou recusado.
- Parecer explicável com fatores que reduzem e que aumentam o risco.
- Pipeline que encadeia todas as etapas e produz a decisão final.
- Testes ExUnit de cada etapa e dos cenários de ponta a ponta.
- Demonstração pelo `iex`.

### 2.2. Fora do MVP

- API web (Phoenix) e interface do analista. A análise manual aparece apenas como status. *Em 20/11/2026 foi adicionada uma interface web de demonstração, sem Phoenix (seção 13).*
- Bancos de dados (Redis e PostgreSQL) e persistência das propostas.
- Modelos treinados (XGBoost, DNNs, Isolation Forest, K-Means) e Nx/Bumblebee.
- NGINX, Kubernetes e implantação em nuvem.
- Integração real com Open Finance.
- Monitoramento de estabilidade (data drift, PSI) e retreinamento.
- Avaliação de equidade (*fairness*).
- Fluxo de recurso e exclusão de dados.

## 3. Tecnologias

As tecnologias dos diagramas formam a **arquitetura final** do sistema. O MVP implementa o núcleo em Elixir e deixa cada etapa isolada em seu próprio módulo, que é o ponto em que a tecnologia de produção seria conectada.

| Componente do diagrama | Tecnologia final (diagramas) | No MVP |
|---|---|---|
| Interface / API | Phoenix | Funções Elixir chamadas pelo `iex` e, desde 20/11/2026, interface web de demonstração com o `:httpd` do Erlang/OTP (seção 13) |
| Feature Store | Redis | Dados dentro da própria proposta |
| Auditoria XAI | PostgreSQL | Parecer devolvido na decisão, sem persistência |
| Circuit Breaker | — | GenServer supervisionado pela `CreditEngine.Application` |
| Motor anti-fraude | Isolation Forest / K-Means | Distância euclidiana até um centro de referência |
| Motor de scoring | XGBoost / DNNs | Fórmula logística com pesos em configuração |
| Gerador de parecer | Valores SHAP | Contribuição de cada variável (peso × valor) |
| Infraestrutura | NGINX, Kubernetes | Não se aplica |

Ferramentas: Elixir com Mix e ExUnit. Nenhuma dependência externa nova.

## 4. Módulos

| Módulo | Função pública | Situação |
|---|---|---|
| `CreditEngine.Proposal` | `new/1` | Concluído (incremento 1) |
| `CreditEngine.Safety.CircuitBreaker` | `evaluate/1`, `status/0` | Concluído (T2) |
| `CreditEngine.ML.Unsupervised` | `detect/1` | Concluído (T3) |
| `CreditEngine.ML.Supervised` | `predict/1` | Concluído (T4) |
| `CreditEngine.Decision.Thresholds` | `classify/1` | Concluído (T5) |
| `CreditEngine.Compliance.XAI` | `explain/2` | Concluído (T6) |
| `CreditEngine.Decision` | struct do resultado | Concluído (T7) |
| `CreditEngine` | `analisar/1` | Concluído (T7) |

## 5. Contratos

Toda etapa recebe a `%CreditEngine.Proposal{}` já validada e devolve uma tupla.

| Etapa | Assinatura | Retornos |
|---|---|---|
| Circuit Breaker | `evaluate(proposal)` | `{:ok, proposal}` ou `{:error, :crise_sistemica}` |
| Anomalias | `detect(proposal)` | `{:ok, proposal}` ou `{:error, :suspeita_fraude}` |
| Score | `predict(proposal)` | `{:ok, probabilidade}`, com probabilidade entre 0 e 1 |
| Limiares | `classify(probabilidade)` | `{:ok, :aprovado \| :analise_manual \| :recusado}` |
| Parecer | `explain(proposal, probabilidade)` | `{:ok, %{fatores_positivos: [...], fatores_negativos: [...]}}` |
| Pipeline | `analisar(atributos)` | `{:ok, %CreditEngine.Decision{}}` ou `{:error, motivo}` |

Regras gerais:

- Campo obrigatório ausente em qualquer etapa: `{:error, {:dado_ausente, campo}}`.
- Valor fora do formato esperado: `{:error, {:dado_invalido, campo}}`.
- No parecer, **fator positivo** é o que reduz o risco (favorável ao cliente) e **fator negativo** é o que aumenta o risco. Cada fator é `%{campo: atom, contribuicao: float}`, ordenado pelo maior impacto.
- Status possíveis da decisão final (`%Decision{status: ...}`): `:aprovado`, `:analise_manual`, `:recusado`, `:recusa_automatica` (Circuit Breaker) e `:recusa_seguranca` (anomalia). Os dois últimos não trazem score nem parecer.

## 6. Dados usados por etapa

Todos os dados são sintéticos. As chaves dentro dos mapas são átomos.

| Etapa | Mapa da proposta | Campos |
|---|---|---|
| Circuit Breaker | `macroeconomic_data` | `taxa_inadimplencia_mercado` (0 a 1) |
| Anomalias | `behavioral_data` | `transacoes_noturnas`, `dispositivos_novos`, `tentativas_login_falhas` |
| Score e parecer | `open_finance_data` | `comprometimento_renda` (0 a 1), `atrasos_12m` |
| Score e parecer | `applicant_data` | `tempo_relacionamento_anos` |

## 7. Valores de demonstração

Ficam em `credit_engine/config/config.exs`, nunca fixos no código. São valores para a demonstração, não calibrados com dados reais.

| Parâmetro | Valor |
|---|---|
| Limite da taxa de inadimplência do mercado | 0,08 (bloqueia acima de 8%) |
| Centro de referência do comportamento | `transacoes_noturnas: 2`, `dispositivos_novos: 0`, `tentativas_login_falhas: 1` |
| Distância máxima até o centro | 3,0 |
| Pesos do score | intercepto −2,0; `comprometimento_renda` 3,0; `atrasos_12m` 0,8; `tempo_relacionamento_anos` −0,3 |
| Limiares | abaixo de 0,30: aprovado; de 0,30 a 0,60: análise manual; acima de 0,60: recusado |

Conferência dos pesos com perfis de exemplo:

| Perfil | Comprometimento / atrasos / tempo | Probabilidade | Status |
|---|---|---|---|
| Bom pagador | 0,2 / 0 / 5 | 0,05 | Aprovado |
| Intermediário | 0,5 / 1 / 2 | 0,43 | Análise manual |
| Mau pagador | 0,8 / 3 / 1 | 0,92 | Recusado |

Os limiares são coerentes com os exemplos do `docs/diagramas/sequencia.md` (0,15 aprovado; 0,40 condicional; 0,80 recusado).

## 8. Critério de pronto

O MVP está pronto quando os cinco cenários abaixo, do `docs/diagramas/sequencia.md`, passarem em testes de ponta a ponta e puderem ser demonstrados pelo `iex`:

1. Recusa automática por colapso de mercado.
2. Recusa de segurança por suspeita de fraude.
3. Crédito aprovado, com parecer.
4. Crédito recusado pelo score, com parecer.
5. Análise manual, com parecer.

## 9. Estratégia de testes

- Testes unitários ExUnit para cada módulo, cobrindo sucesso, dado ausente e dado inválido.
- Testes de ponta a ponta para os cinco cenários da seção 8.
- Os testes leem os parâmetros da configuração, sem números soltos.
- Antes de cada envio: `mix format --check-formatted` e `mix test`.

## 10. Riscos

| Risco | Mitigação |
|---|---|
| Prazo de três dias | Etapas independentes, feitas em paralelo, com contratos fixos |
| Conflitos de merge | Um módulo por pessoa; `config/config.exs` criado antes, na tarefa T0 |
| Divergência entre diagrama e código | Nomes de módulos deste plano; correções do diagrama de classes ficam em DP21 |
| Ambientes diferentes entre integrantes | Sem dependências externas; Elixir 1.14 ou superior |

## 11. Cronograma

| Data | Atividade |
|---|---|
| 17/11 (ter) | T0 e tarefas T2 a T6, em paralelo |
| 18/11 (qua) | T7 (pipeline) e T8 (cenários de ponta a ponta) |
| 19/11 (qui) | T9 (verificação e documentação). O escopo fecha. |
| 21 a 22/11 | Correções e roteiro da demonstração |
| 23/11 (seg) | Ajustes finais e ensaio |
| 24/11 (ter) | Evento final |

## 12. Rastreabilidade

| Origem | Relação com o plano |
|---|---|
| `docs/diagramas/sequencia.md` | Ordem das etapas, cenários e contrato de resposta |
| `docs/diagramas/diagrama-de-classes.md` | Nomes dos módulos |
| `docs/diagramas/diagrama-de-componentes.md` | Separação por etapas e portas |
| `docs/decisoes-pendentes.md` | DP01, DP02, DP03, DP04, DP10, DP11, DP12, DP14 e DP15 |
| `spec.md` | Incremento 1, base da proposta validada |

## 13. Interface web de demonstração (T10)

Adicionada em 20/11/2026 para deixar a apresentação mais visual. A demonstração pelo `iex` continua valendo.

- **O que faz:** uma página web recebe a proposta, chama `CreditEngine.analisar/1` e mostra as etapas do pipeline, a decisão, o score e o parecer.
- **Como:** sem Phoenix nem dependência externa. O servidor é o `:httpd`, que já vem com o Erlang/OTP (aplicação `:inets`), e aceita conexões apenas do próprio computador.
- **O que não muda:** nenhuma regra de negócio, contrato ou valor de demonstração. A interface só chama o pipeline. O restante da seção 2.2 continua fora do MVP, inclusive a interface do analista e a persistência.
