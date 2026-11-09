# Instruções para assistentes de programação

## Fonte de verdade

Antes de implementar:
1. Leia `README.md` e `docs/planejamento-original.md`, se disponíveis.
2. Consulte a especificação e as tarefas da funcionalidade, caso existam.
3. Identifique documentos ausentes ou incompletos antes de depender deles.
4. 4. Em caso de conflito entre documentos, apresente o conflito e não escolha silenciosamente qual seguir. Considere os requisitos explicitamente aprovados pelo usuário como referência principal e solicite esclarecimento quando necessário.
5. Use os diagramas e o planejamento da disciplina como referência, sem presumir que detalhes ilegíveis ou ambíguos estejam confirmados.

## Regras de trabalho

- Antes de implementar, verifique se os requisitos da tarefa estão suficientemente claros.
- Se faltarem informações essenciais, pergunte ao usuário antes de tomar decisões de negócio ou arquitetura.
- Não exija que toda a documentação do projeto esteja concluída para implementar uma tarefa já bem definida.
- Não invente regras de negócio, pesos de score, limites, fontes de dados ou decisões automáticas que não estejam documentados.
- Preserve os diagramas e a intenção do planejamento. Sugira mudanças arquiteturais separadamente, com justificativa.
- Faça mudanças pequenas, relacionadas à tarefa atual.
- Não declare testes aprovados sem executá-los; informe comandos, resultados e limitações.
- Não use dados pessoais reais de clientes nos testes ou exemplos. Prefira dados sintéticos.
- Não exponha credenciais, tokens ou dados sensíveis em código, logs, documentação ou commits.
- Registre falhas, indisponibilidade de fontes, dados ausentes e decisões encaminhadas para análise humana.
- Em decisões de crédito, produza explicações rastreáveis e permita revisão humana nos casos definidos pela especificação.
- Não interprete os diagramas como prova de que toda tecnologia já foi escolhida para implementação.

## Ao concluir uma tarefa

Informe:
1. O que foi alterado.
2. Quais arquivos foram afetados.
3. Quais requisitos e critérios de aceitação foram atendidos.
4. Quais testes foram executados e seus resultados.
5. O que permanece pendente.
6. Se algum documento precisa ser atualizado.

## Protocolo de mudança

Se a implementação exigir alteração de requisito ou arquitetura:
1. Não execute a alteração que extrapola o escopo sem aprovação.
2. Explique a necessidade e o impacto.
3. Proponha a atualização de `spec.md`, `plan.md` ou `tasks.md`.
4. Aguarde aprovação antes de realizar essa alteração.