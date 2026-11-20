# CLAUDE.md

Instruções para o Claude Code no projeto **Sistema Inteligente de Análise de Crédito**.

## Sobre o projeto

Projeto acadêmico da Equipe Omicron, na disciplina de Conceitos de Linguagens de Programação (CLP) da UFAL. O sistema apoia a avaliação de propostas de crédito: processa dados de diferentes fontes, estima o risco de inadimplência, identifica possíveis anomalias e gera explicações rastreáveis para cada resultado. Propostas em situação de incerteza podem ser encaminhadas para análise humana.

## Regras obrigatórias

Siga as instruções de @AGENTS.md em todas as tarefas. Em resumo: não invente regras de negócio, limites ou tecnologias; pergunte quando faltar informação essencial; use apenas dados sintéticos; não declare testes aprovados sem executá-los.

## Tecnologias

- **Em uso:** Elixir, com projeto Mix e testes ExUnit em `credit_engine/`, GenServer no Circuit Breaker e `:httpd` (Erlang/OTP) na interface web. Sem dependências externas.
- **Decisão do MVP (17/11):** as tecnologias dos diagramas formam a arquitetura final; o MVP usa Elixir puro com GenServer. Ver `plan.md`, seção 3.
- **Arquitetura final, fora do MVP:** Phoenix, Nx/Bumblebee, XGBoost, DNNs, Redis, PostgreSQL, NGINX, Kubernetes, Isolation Forest e K-Means. Não adicione nenhuma delas como dependência sem aprovação da equipe.
- **Previsto no quadro da equipe e ainda não adicionado:** Credo.

## Arquitetura planejada

Conforme o diagrama de pacotes, o sistema se organiza em cinco áreas:

| Área | Responsabilidade |
|---|---|
| Ingestão Multimodal | Receber e integrar os dados da proposta |
| Segurança Sistêmica | Circuit Breaker ligado ao contexto macroeconômico |
| Core IA | Detecção de anomalias e previsão de risco |
| Decisão e Conformidade | Limiares de decisão e explicabilidade (SHAP) |
| MLOps (Assíncrono) | Monitoramento da estabilidade dos modelos |

Sequência representada nos diagramas de pacotes e de sequência: ingestão → Circuit Breaker → detecção de anomalias → motor preditivo → limiares de decisão → parecer explicável. Detalhes e pontos em aberto estão em `docs/diagramas/`.

## Convenções de código

- Funções que podem falhar retornam `{:ok, valor}` ou `{:error, motivo}`, padrão usado no diagrama de classes e previsto no quadro da equipe.
- Trate esses retornos com pattern matching.
- Testes e exemplos usam somente dados sintéticos.
- Não versione credenciais, tokens nem dados pessoais.

## Como trabalhar

Siga o fluxo de `docs/fluxo-sdd.md`: especificar, revisar, planejar, dividir em tarefas, implementar uma tarefa por vez, testar, verificar e atualizar a documentação. Nunca gere o sistema inteiro de uma vez.

Combinado da equipe: ao concluir uma tarefa, atualize o `README.md` se a mudança afetar o que ele descreve.

## Onde está cada coisa

| Arquivo | Conteúdo |
|---|---|
| `README.md` | Visão geral, situação atual e decisões pendentes |
| `AGENTS.md` | Regras para assistentes de programação |
| `docs/fluxo-sdd.md` | Fluxo de trabalho e prompts de cada etapa |
| `plan.md` | Plano técnico do MVP: escopo, contratos, dados e valores de demonstração |
| `tasks.md` | Tarefas do MVP (T0 a T9), com testes e critérios de conclusão |
| `spec.md` | Especificação do incremento 1 (recebimento e validação de propostas) |
| `docs/verificacao-incremento-01.md` | Verificação do incremento 1 contra o `spec.md` |
| `docs/verificacao-mvp.md` | Verificação do MVP contra o `plan.md` |
| `credit_engine/` | Projeto Elixir: código em `lib/`, testes em `test/` |
| `docs/decisoes-pendentes.md` | Decisões que a equipe ainda precisa aprovar |
| `docs/diagramas/` | Descrição dos diagramas UML; as seções "Pontos a esclarecer" são questões em aberto, não decisões aprovadas |

## Comandos

Execute a partir da pasta `credit_engine/`:

- `mix compile` — compilar
- `mix test` — rodar os testes
- `mix format` — formatar o código
- `iex -S mix` — console interativo

## Situação atual

- Documentação e diagramas no repositório.
- MVP definido em 17/11 no `plan.md`, com as tarefas em `tasks.md`.
- Projeto Elixir criado em `credit_engine/`.
- Primeiro incremento implementado e verificado: recebimento e validação de propostas (`CreditEngine.Proposal`). Resultados em `docs/verificacao-incremento-01.md`. O `spec.md` aguarda aprovação da equipe.
- Circuit Breaker (T2), detecção de anomalias (T3), score de risco (T4), limiares de decisão (T5), parecer explicável (T6) e o pipeline `CreditEngine.analisar/1` (T7) estão implementados. Os cinco cenários de ponta a ponta (T8) passam e a demonstração pelo `iex` está em `credit_engine/README.md`. A verificação final (T9) está em `docs/verificacao-mvp.md`: 92 testes, 0 falhas, e o MVP atende ao critério de pronto.
- Interface web de demonstração (T10), adicionada em 20/11 (`plan.md`, seção 13): `:httpd` do Erlang/OTP, sem Phoenix nem dependências externas. Abre com `mix credit_engine.web`. Total atual: 108 testes, 0 falhas.
- Decisões em aberto consolidadas em `docs/decisoes-pendentes.md`.
