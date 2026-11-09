# CLAUDE.md

Instruções para o Claude Code no projeto **Sistema Inteligente de Análise de Crédito**.

## Sobre o projeto

Projeto acadêmico da Equipe Omicron, na disciplina de Conceitos de Linguagens de Programação (CLP) da UFAL. O sistema apoia a avaliação de propostas de crédito: processa dados de diferentes fontes, estima o risco de inadimplência, identifica possíveis anomalias e gera explicações rastreáveis para cada resultado. Propostas em situação de incerteza podem ser encaminhadas para análise humana.

## Regras obrigatórias

Siga as instruções de @AGENTS.md em todas as tarefas. Em resumo: não invente regras de negócio, limites ou tecnologias; pergunte quando faltar informação essencial; use apenas dados sintéticos; não declare testes aprovados sem executá-los.

## Tecnologias

- **Definida:** Elixir.
- **Mencionadas nos diagramas, ainda não aprovadas:** Phoenix, Nx/Bumblebee, XGBoost, DNNs, Redis, PostgreSQL, NGINX, Kubernetes, Isolation Forest e K-Means. Não adicione nenhuma delas como dependência sem aprovação da equipe.
- **Previstas no quadro da equipe:** ExUnit para testes, `mix format` e Credo.

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
| `docs/diagramas/` | Descrição dos diagramas UML; as seções "Pontos a esclarecer" são questões em aberto, não decisões aprovadas |

## Situação atual

- Documentação e diagramas no repositório.
- Escopo do MVP ainda não definido. O escopo fecha em 19/11.
- Projeto Elixir ainda não criado. Quando for criado, registre aqui os comandos de compilação, testes e formatação.
- Ainda não enviado: `docs/decisoes-pendentes.md`.
