# Verificação do MVP

## 1. Objetivo

Este documento registra a verificação do MVP contra o `plan.md`, conforme a Etapa 5 do `docs/fluxo-sdd.md` e a tarefa T9 do `tasks.md`.

A verificação não presume que o código está correto. Cada item foi conferido por um teste automatizado executado ou por um comando executado no console, e os resultados abaixo são os resultados reais obtidos. Onde a evidência é parcial, o resultado diz isso.

## 2. Ambiente e comandos

- **Data:** 19/11/2026.
- **Ponto de partida:** commit `5703d62` do branch `main`.
- **Ambiente:** Elixir 1.14.0 e Erlang/OTP 25, em Linux.

Comandos executados na pasta `credit_engine/`:

```bash
mix compile --force --warnings-as-errors
mix format --check-formatted
mix test
mix test --seed N          # N de 0 a 9
mix test <arquivo>         # cada arquivo de teste separadamente
mix run <script>           # conferência da configuração e de casos de borda
iex -S mix                 # comandos da demonstração do credit_engine/README.md
```

O ambiente usado não é o computador de nenhum integrante. Recomenda-se repetir `mix test` em pelo menos uma máquina da equipe antes do ensaio.

## 3. Resultados da execução

| Verificação | Resultado |
|---|---|
| Compilação com `--warnings-as-errors` | Sem avisos |
| `mix format --check-formatted` | Sem pendências |
| `mix test` | 92 testes, 0 falhas |
| `mix test` com as seeds 0 a 9 | 92 testes, 0 falhas nas 10 execuções |
| Comandos da demonstração no `iex` | As 7 saídas são idênticas às do `credit_engine/README.md` |

Testes por arquivo:

| Arquivo | Testes | Falhas |
|---|---|---|
| `test/credit_engine/cenarios_test.exs` | 5 | 0 |
| `test/credit_engine/compliance/xai_test.exs` | 9 | 0 |
| `test/credit_engine/config_test.exs` | 4 | 0 |
| `test/credit_engine/core_test.exs` | 3 | 0 |
| `test/credit_engine/decision/thresholds_test.exs` | 10 | 0 |
| `test/credit_engine/ml/supervised_test.exs` | 14 | 0 |
| `test/credit_engine/ml/unsupervised_test.exs` | 11 | 0 |
| `test/credit_engine/pipeline_test.exs` | 10 | 0 |
| `test/credit_engine/proposal_test.exs` | 11 | 0 |
| `test/credit_engine/safety/circuit_breaker_test.exs` | 13 | 0 |
| `test/credit_engine_test.exs` | 2 | 0 |
| **Total** | **92** | **0** |

## 4. Critério de pronto (seção 8 do `plan.md`)

| Cenário | Evidência (teste) | Evidência (`iex`) | Resultado |
|---|---|---|---|
| 1. Recusa automática por colapso de mercado | Cenário 1 em `cenarios_test.exs` | `credit_engine/README.md`, demonstração 1 | Passou |
| 2. Recusa de segurança por suspeita de fraude | Cenário 2 em `cenarios_test.exs` | `credit_engine/README.md`, demonstração 2 | Passou |
| 3. Crédito aprovado, com parecer | Cenário 3 em `cenarios_test.exs` | `credit_engine/README.md`, demonstração 3 | Passou |
| 4. Crédito recusado pelo score, com parecer | Cenário 4 em `cenarios_test.exs` | `credit_engine/README.md`, demonstração 4 | Passou |
| 5. Análise manual, com parecer | Cenário 5 em `cenarios_test.exs` | `credit_engine/README.md`, demonstração 5 | Passou |

Os testes dos cenários 1 e 2 também conferem que as etapas seguintes não são executadas: a análise é repetida sem os dados dessas etapas, e a decisão continua a mesma (se elas rodassem, o resultado seria `dado_ausente`). Na T8, a ordem das etapas foi trocada de propósito no código, e os testes acusaram a falha nos dois casos (Circuit Breaker depois das anomalias e score antes das anomalias).

## 5. Escopo incluído (seção 2.1 do `plan.md`)

| Item | Evidência | Resultado |
|---|---|---|
| Validação da proposta | `proposal_test.exs` (11 testes) e `docs/verificacao-incremento-01.md` | Atendido |
| Circuit Breaker pela taxa de inadimplência do mercado | `circuit_breaker_test.exs` (13 testes) | Atendido |
| Detecção de anomalias por distância euclidiana | `unsupervised_test.exs` (11 testes), incluindo o cálculo da distância | Atendido |
| Score de risco por fórmula logística | `supervised_test.exs` (14 testes), incluindo a conferência da fórmula com a configuração | Atendido |
| Classificação por limiares | `thresholds_test.exs` (10 testes) | Atendido |
| Parecer com fatores que reduzem e que aumentam o risco | `xai_test.exs` (9 testes) | Atendido |
| Pipeline que encadeia as etapas e produz a decisão final | `pipeline_test.exs` (10 testes) | Atendido |
| Testes de cada etapa e dos cenários de ponta a ponta | Seções 3 e 4 | Atendido |
| Demonstração pelo `iex` | `credit_engine/README.md`, saídas conferidas no `iex` | Atendido |

## 6. Contratos (seção 5 do `plan.md`)

| Contrato | Evidência | Resultado |
|---|---|---|
| `CircuitBreaker.evaluate/1`: `{:ok, proposal}` ou `{:error, :crise_sistemica}` | Testes de taxa abaixo, igual e acima do limite | Passou |
| `Unsupervised.detect/1`: `{:ok, proposal}` ou `{:error, :suspeita_fraude}` | Testes de distância abaixo, igual e acima da máxima | Passou |
| `Supervised.predict/1`: `{:ok, probabilidade}`, entre 0 e 1 | Teste "o resultado fica entre 0 e 1, inclusive com valores extremos" | Passou |
| `Thresholds.classify/1`: `:aprovado`, `:analise_manual` ou `:recusado` | Testes com os exemplos do `sequencia.md` e nos limites | Passou |
| `XAI.explain/2`: `fatores_positivos` e `fatores_negativos` | Testes de sinal, de ordenação e de peso × valor | Passou |
| `CreditEngine.analisar/1`: `{:ok, %Decision{}}` ou `{:error, motivo}` | Testes de cada status e de entrada inválida | Passou |
| Campo ausente: `{:error, {:dado_ausente, campo}}` | Testes de dado ausente no Circuit Breaker, nas anomalias, no score, no parecer e no pipeline | Passou |
| Valor fora do formato: `{:error, {:dado_invalido, campo}}` | Testes de dado inválido nos mesmos módulos e nos limiares | Passou |
| Fator positivo reduz o risco, fator negativo aumenta, cada um `%{campo, contribuicao}` ordenado pelo impacto | `xai_test.exs` e cenários 3 a 5 | Passou |
| Recusa automática e de segurança sem score nem parecer | Cenários 1 e 2 e `pipeline_test.exs` comparam a decisão inteira, com `score: nil` e `explanation: nil` | Passou |

## 7. Valores de demonstração (seção 7 do `plan.md`)

A configuração carregada pela aplicação (`Application.get_all_env(:credit_engine)`) foi comparada com a tabela do `plan.md`: limite 0,08; centro `2 / 0 / 1`; distância máxima 3,0; intercepto −2,0; pesos 3,0, 0,8 e −0,3; limiares 0,30 e 0,60. **Todos os valores conferem.** Nenhum desses valores aparece fixo no código de `lib/`.

Perfis de exemplo, executados pelo pipeline:

| Perfil | Probabilidade obtida | Status obtido | Esperado no `plan.md` | Resultado |
|---|---|---|---|---|
| Bom pagador (0,2 / 0 / 5) | 0,0522 | `:aprovado` | 0,05, aprovado | Passou |
| Intermediário (0,5 / 1 / 2) | 0,4256 | `:analise_manual` | 0,43, análise manual | Passou |
| Mau pagador (0,8 / 3 / 1) | 0,9241 | `:recusado` | 0,92, recusado | Passou |

## 8. Estratégia de testes (seção 9 do `plan.md`)

| Item | Evidência | Resultado |
|---|---|---|
| Testes de cada módulo cobrindo sucesso, dado ausente e dado inválido | Circuit Breaker, anomalias, score, parecer e pipeline têm os três casos. A proposta usa os erros do `spec.md` (`:invalid_id`, `{:invalid_field, campo}` etc.). Os limiares recebem só a probabilidade, e `nil` é tratado como dado inválido (decisão da T5). | Atendido |
| Testes de ponta a ponta para os cinco cenários | Seção 4 | Atendido |
| Testes leem os parâmetros da configuração, sem números soltos | Os testes do Circuit Breaker, das anomalias, dos limiares e dos cenários leem os parâmetros da configuração. Outros testes usam diretamente os perfis e exemplos do `plan.md` e do `sequencia.md` (por exemplo, probabilidade próxima de 0,92, taxa 0,10 e 10 transações noturnas no `pipeline_test.exs`), e precisariam ser revistos se a configuração mudar. | Atendido em parte |
| `mix format --check-formatted` e `mix test` antes de cada envio | Executados antes de cada commit de T3 a T8 e nesta verificação | Atendido |

## 9. Tecnologias e arquitetura (seção 3 do `plan.md`)

| Item | Evidência | Resultado |
|---|---|---|
| Nenhuma dependência externa | `mix.exs` com `deps: []` | Atendido |
| Circuit Breaker como GenServer supervisionado | `Supervisor.which_children(CreditEngine.Supervisor)` lista o `CircuitBreaker`; teste "o processo aparece sob o supervisor da aplicação" | Atendido |
| Uma etapa por módulo, com os nomes do plano | Módulos da seção 4 do `plan.md` existem com as funções previstas | Atendido |
| Pipeline com `with` e tuplas `{:ok, _} \| {:error, _}` | `credit_engine/lib/credit_engine.ex` | Atendido |

## 10. Tarefas

| Tarefa | Situação | Evidência |
|---|---|---|
| T0 a T8 | Concluídas | `tasks.md` e seções 3 a 9 deste documento |
| T9 | Concluída | Este documento |

O cronograma do `plan.md` previa T7 e T8 para 18/11. As duas foram concluídas em 19/11.

## 11. Pendências e limitações

1. **Ambiente de execução:** os testes foram executados fora das máquinas da equipe. Recomenda-se repetir `mix test` localmente antes do ensaio de 23/11.
2. **Números fixos em parte dos testes:** ver seção 8. Se algum valor de `config.exs` mudar, os testes de perfis, do parecer e do pipeline precisam ser revistos junto.
3. **O parecer não usa a probabilidade:** `XAI.explain/2` recebe a probabilidade, como pede o contrato, mas só a valida. As contribuições dependem apenas da proposta. Por isso, nenhum teste consegue detectar se o pipeline passa ao parecer uma probabilidade diferente da calculada. Na arquitetura final, com valores SHAP, a probabilidade passaria a fazer parte do cálculo.
4. **Chaves internas em texto:** as chaves dentro dos mapas da proposta precisam ser átomos (`plan.md`, seção 6). Com `%{"taxa_inadimplencia_mercado" => 0.05}`, o resultado é `{:error, {:dado_ausente, :taxa_inadimplencia_mercado}}`. As chaves de primeiro nível podem ser texto, conforme o incremento 1.
5. **Empate no perfil mau pagador:** atrasos (0,8 × 3) e comprometimento de renda (3,0 × 0,8) têm a mesma contribuição, 2,4. A ordem entre os dois no parecer não indica que um pesa mais. Isso está explicado no `credit_engine/README.md`.
6. **Contador do Circuit Breaker:** `status/0` conta os bloqueios desde que a aplicação subiu. Na demonstração, o número depende de quantas vezes o cenário 1 foi executado na mesma sessão do `iex`.
7. **Aprovação do `spec.md`:** a especificação do incremento 1 continua com o status "aguardando revisão".
8. **Credo:** previsto no quadro da equipe, ainda não foi configurado.
9. **Decisões em aberto:** DP05 a DP09, DP13 e DP16 a DP24 continuam em aberto em `docs/decisoes-pendentes.md`. Nenhuma delas é necessária para os cinco cenários do MVP.

## 12. Conclusão

Os cinco cenários do critério de pronto passam em testes de ponta a ponta e podem ser demonstrados pelo `iex`, e os contratos e os valores do `plan.md` conferem com o código. **O MVP atende ao critério de pronto da seção 8 do `plan.md`.** O único item atendido em parte é o uso de números fixos em alguns testes (seção 8), que não afeta o funcionamento.

## 13. Complemento de 20/11/2026: interface web

Depois desta verificação, a equipe adicionou a interface web de demonstração (T10), descrita no `plan.md`, seção 13. A interface não altera o pipeline: só converte os campos do formulário e chama `CreditEngine.analisar/1`.

| Verificação | Resultado |
|---|---|
| `mix test` | 108 testes, 0 falhas (92 anteriores + 16 da interface), também com as seeds 0 a 5 |
| Testes da interface | Decisão da API igual à de `CreditEngine.analisar/1`; etapas executadas em cada tipo de recusa; erros 422 com o campo; rotas `/`, `/api/analisar`, `/api/status` e 404 por HTTP; servidor só em `127.0.0.1` |
| Navegador (Chromium) | Cinco cenários e uma entrada inválida conferidos em largura de computador e de celular |

### Reexecução no Codespace — 20/11/2026

- **Ambiente:** Ubuntu 24.04.5 LTS, Elixir 1.14.0 e Erlang/OTP 25.
- `mix test`: 108 testes, 0 falhas (seed 412181).
- `mix format --check-formatted`: concluído sem arquivos fora do padrão.
- `mix compile --warnings-as-errors`: compilação concluída sem avisos.

## 14. Referências

- `plan.md`, seções 2 a 9.
- `tasks.md`, tarefas T0 a T10.
- `docs/fluxo-sdd.md`, Etapa 5.
- `docs/diagramas/sequencia.md`, cenários BDD.
- `docs/verificacao-incremento-01.md`, verificação do incremento 1.
- `credit_engine/README.md`, seção de demonstração.
