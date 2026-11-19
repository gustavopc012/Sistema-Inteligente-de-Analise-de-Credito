## Tarefas do MVP

**Projeto:** Sistema Inteligente de Análise de Crédito  
**Base:** `plan.md` (definido em 17/11/2026)  
**Prazo:** escopo fecha em 19/11/2026

Este documento corresponde à Etapa 3 do `docs/fluxo-sdd.md`. Cada tarefa indica objetivo, arquivos, testes e critério de conclusão. Para pegar uma tarefa, avise no grupo e preencha o responsável aqui.

As tarefas T2 a T6 são independentes e podem ser feitas em paralelo, depois da T0. Todos os nomes, contratos, campos e valores vêm do `plan.md`.

## Resumo

| Tarefa | Descrição | Depende de | Responsável | Situação |
|---|---|---|---|---|
| T0 | Configuração dos valores de demonstração | — | Alan | Concluída |
| T1 | Recebimento e validação da proposta | — | Gustavo | Concluída |
| T2 | Circuit Breaker | T0 | Paulo | Concluída |
| T3 | Detecção de anomalias | T0 | | A fazer |
| T4 | Score de risco | T0 | Alan | Concluída |
| T5 | Limiares de decisão | T0 | | A fazer |
| T6 | Parecer explicável | T0 | | A fazer |
| T7 | Pipeline completo | T2 a T6 | | A fazer |
| T8 | Cenários de ponta a ponta e demonstração | T7 | | A fazer |
| T9 | Verificação e documentação final | T8 | | A fazer |

Regras para todas as tarefas:

- Antes de enviar: `mix format --check-formatted` e `mix test` sem falhas.
- Testes usam os valores de `config/config.exs`, nunca números soltos.
- Dados de teste sempre sintéticos.
- Ao concluir, atualizar a situação nesta tabela e, se necessário, o `README.md`.
**Complementado em 19/11/2026 (T2): taxa igual ao limite não bloqueia; `macroeconomic_data` ausente ou campo `nil` devolve `{:dado_ausente, :taxa_inadimplencia_mercado}`; valor não numérico ou fora de 0 a 1 devolve `{:dado_invalido, :taxa_inadimplencia_mercado}` e não conta como bloqueio (`tasks.md`, T2).**
---

## T0 — Configuração dos valores de demonstração

**Objetivo:** criar o arquivo de configuração com todos os parâmetros da seção 7 do `plan.md`, para que T2 a T6 não editem o mesmo arquivo ao mesmo tempo.

**Arquivos:** `credit_engine/config/config.exs`.

**Testes:** `mix test` continua passando.

**Concluída quando:** o arquivo existe com o limite do Circuit Breaker, o centro e a distância máxima das anomalias, os pesos do score e os dois limiares, e cada valor pode ser lido com `Application.fetch_env!/2`.

**Situação:** concluída em 17/11/2026. Chaves disponíveis:

| Chave | Valores |
|---|---|
| `:circuit_breaker` | `limite_taxa_inadimplencia` |
| `:anomalias` | `centro` (mapa com os três campos), `distancia_maxima` |
| `:score` | `intercepto`, `pesos` (mapa com os três campos) |
| `:limiares` | `aprovado_abaixo_de`, `recusado_acima_de` |

Exemplo de leitura: `Application.fetch_env!(:credit_engine, :score)[:pesos]`. Testes em `test/credit_engine/config_test.exs`.

---

## T1 — Recebimento e validação da proposta

**Situação:** concluída. Especificação em `spec.md` e verificação em `docs/verificacao-incremento-01.md`.

---

## T2 — Circuit Breaker

**Objetivo:** recusar a proposta quando a taxa de inadimplência do mercado passar do limite configurado.

**Arquivos:** `lib/credit_engine/safety/circuit_breaker.ex`, `lib/credit_engine/application.ex`, `test/credit_engine/safety/circuit_breaker_test.exs`.

**Contrato:** `evaluate(proposal)` devolve `{:ok, proposal}` ou `{:error, :crise_sistemica}`. `status/0` devolve o limite em uso e quantas propostas foram bloqueadas.

**Implementação:** GenServer iniciado pela `CreditEngine.Application`, lendo o limite da configuração.

**Testes:**
- taxa abaixo do limite: `{:ok, proposal}`;
- taxa acima do limite: `{:error, :crise_sistemica}`;
- campo ausente: `{:error, {:dado_ausente, :taxa_inadimplencia_mercado}}`;
- valor não numérico: `{:error, {:dado_invalido, :taxa_inadimplencia_mercado}}`;
- `status/0` conta os bloqueios.
- taxa fora de 0 a 1: {:error, {:dado_invalido, :taxa_inadimplencia_mercado}};

**Concluída quando:** os testes passam e o processo aparece sob o supervisor da aplicação.

---

## T3 — Detecção de anomalias

**Objetivo:** recusar por segurança a proposta cujo comportamento está distante demais do centro de referência.

**Arquivos:** `lib/credit_engine/ml/unsupervised.ex`, `test/credit_engine/ml/unsupervised_test.exs`.

**Contrato:** `detect(proposal)` devolve `{:ok, proposal}` ou `{:error, :suspeita_fraude}`.

**Implementação:** distância euclidiana entre os três campos de `behavioral_data` e o centro configurado, comparada à distância máxima.

**Testes:**
- comportamento próximo do centro: `{:ok, proposal}`;
- comportamento distante: `{:error, :suspeita_fraude}`;
- campo ausente ou não numérico: erro de dado ausente ou inválido.

**Concluída quando:** os testes passam.

---

## T4 — Score de risco

**Objetivo:** calcular a probabilidade de inadimplência da proposta.

**Arquivos:** `lib/credit_engine/ml/supervised.ex`, `test/credit_engine/ml/supervised_test.exs`.

**Contrato:** `predict(proposal)` devolve `{:ok, probabilidade}`, com probabilidade entre 0 e 1.

**Implementação:** fórmula logística `1 / (1 + e^(-z))`, em que `z` é o intercepto mais a soma de peso × valor de cada campo, com os pesos da configuração.

**Testes:**
- os três perfis de exemplo do `plan.md` (bom pagador, intermediário e mau pagador) produzem probabilidades próximas de 0,05, 0,43 e 0,92;
- o resultado fica sempre entre 0 e 1;
- campo ausente ou não numérico: erro de dado ausente ou inválido.

**Concluída quando:** os testes passam.

**Situação:** concluída em 19/11/2026, com 14 testes em `test/credit_engine/ml/supervised_test.exs`.

**Complementado em 19/11/2026 (T4):** `comprometimento_renda` precisa estar entre 0 e 1; `atrasos_12m` e `tempo_relacionamento_anos` precisam ser números maiores ou iguais a 0. Mapa ausente, campo ausente ou `nil` devolve `{:dado_ausente, campo}`; valor fora dessas regras devolve `{:dado_invalido, campo}`.

Também foi exposta a função `contribuicoes(proposal)`, que devolve `{:ok, %{campo => peso × valor}}` com a mesma conta do score. A T6 pode usá-la para montar o parecer sem repetir a leitura e a validação dos campos.

---

## T5 — Limiares de decisão

**Objetivo:** transformar a probabilidade em status.

**Arquivos:** `lib/credit_engine/decision/thresholds.ex`, `test/credit_engine/decision/thresholds_test.exs`.

**Contrato:** `classify(probabilidade)` devolve `{:ok, :aprovado | :analise_manual | :recusado}`.

**Testes:**
- exemplos do `sequencia.md`: 0,15 aprovado; 0,40 análise manual; 0,80 recusado;
- valores exatamente nos limites (0,30 e 0,60) caem em análise manual;
- valor fora de 0 a 1 ou não numérico: `{:error, {:dado_invalido, :probabilidade}}`.

**Concluída quando:** os testes passam.

---

## T6 — Parecer explicável

**Objetivo:** explicar quais fatores reduziram e quais aumentaram o risco.

**Arquivos:** `lib/credit_engine/compliance/xai.ex` (novo), `test/credit_engine/compliance/xai_test.exs`.

**Contrato:** `explain(proposal, probabilidade)` devolve `{:ok, %{fatores_positivos: [...], fatores_negativos: [...]}}`. Cada fator é `%{campo: atom, contribuicao: float}`.

**Implementação:** contribuição de cada campo = peso × valor, com os pesos do score. Contribuição negativa reduz o risco (fator positivo); contribuição positiva aumenta o risco (fator negativo). Cada lista é ordenada pelo maior impacto.

**Testes:**
- no perfil mau pagador, `comprometimento_renda` e `atrasos_12m` aparecem como fatores negativos;
- `tempo_relacionamento_anos` aparece como fator positivo;
- as listas estão ordenadas pelo impacto.

**Concluída quando:** os testes passam.

---

## T7 — Pipeline completo

**Objetivo:** encadear todas as etapas e produzir a decisão final.

**Arquivos:** `lib/credit_engine.ex`, `test/credit_engine/pipeline_test.exs`.

**Contrato:** `analisar(atributos)` devolve `{:ok, %CreditEngine.Decision{}}` ou `{:error, motivo}` para entrada inválida.

**Implementação:** `with` encadeando `Proposal.new/1`, `CircuitBreaker.evaluate/1`, `Unsupervised.detect/1`, `Supervised.predict/1`, `Thresholds.classify/1` e `XAI.explain/2`. `{:error, :crise_sistemica}` vira `%Decision{status: :recusa_automatica}` e `{:error, :suspeita_fraude}` vira `%Decision{status: :recusa_seguranca}`, ambos sem score nem parecer.

**Testes:** um teste por status possível e um para entrada inválida.

**Concluída quando:** os testes passam.

---

## T8 — Cenários de ponta a ponta e demonstração

**Objetivo:** comprovar o critério de pronto da seção 8 do `plan.md` e preparar a demonstração.

**Arquivos:** `test/credit_engine/cenarios_test.exs`, `credit_engine/README.md` (seção de demonstração).

**Testes:** os cinco cenários do `sequencia.md`: recusa automática, recusa de segurança, aprovado, recusado e análise manual.

**Concluída quando:** os cinco cenários passam e o `credit_engine/README.md` traz os comandos de `iex` para demonstrar cada um.

---

## T9 — Verificação e documentação final

**Objetivo:** verificar o MVP contra o `plan.md` (Etapa 5 do fluxo SDD) e fechar o escopo.

**Arquivos:** `docs/verificacao-mvp.md` (novo), `README.md`, `CLAUDE.md`, `tasks.md`.

**Concluída quando:** existe a tabela requisito, evidência e resultado, com os resultados reais de `mix test`, e os documentos refletem o que foi entregue.
