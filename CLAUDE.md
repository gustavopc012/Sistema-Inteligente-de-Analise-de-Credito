# CLAUDE.md

Instruções para o Claude Code no projeto **Sistema Inteligente de Análise de Crédito**.

## Sobre o projeto

Projeto acadêmico da Equipe Omicron, na disciplina de Conceitos de Linguagens de Programação (CLP) da UFAL. O sistema apoia a avaliação de propostas de crédito: processa dados de diferentes fontes, estima o risco de inadimplência, identifica possíveis anomalias e gera explicações rastreáveis para cada resultado. Propostas em situação de incerteza podem ser encaminhadas para análise humana.

## Regras obrigatórias

Siga as instruções de @AGENTS.md em todas as tarefas. Em resumo: não invente regras de negócio, limites ou tecnologias; pergunte quando faltar informação essencial; use apenas dados sintéticos; não declare testes aprovados sem executá-los.

## Tecnologias

- **Em uso:** Elixir, com projeto Mix e testes ExUnit em `credit_engine/`. Sem dependências externas nesta etapa.
- **Mencionadas nos diagramas, ainda não aprovadas:** Phoenix, Nx/Bumblebee, XGBoost, DNNs, Redis, PostgreSQL, NGINX, Kubernetes, Isolation Forest e K-Means. Não adicione nenhuma delas como dependência sem aprovação da equipe.
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
| `spec.md` | Especificação do incremento atual (recebimento e validação de propostas) |
| `docs/verificacao-incremento-01.md` | Verificação do incremento 1 contra o `spec.md` |
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
- Escopo do MVP ainda não definido. O escopo fecha em 19/11.
- Projeto Elixir criado em `credit_engine/`.
- Primeiro incremento implementado e verificado: recebimento e validação de propostas (`CreditEngine.Proposal`). Resultados em `docs/verificacao-incremento-01.md`. O `spec.md` aguarda aprovação da equipe.
- Circuit Breaker, limiares de decisão e módulos de ML são esqueletos que retornam `{:error, :not_implemented}` até serem especificados.
- Decisões em aberto consolidadas em `docs/decisoes-pendentes.md`.
