# Fluxo de trabalho SDD — Sistema Inteligente de Análise de Crédito

Este fluxo é manual e pode ser utilizado com diferentes assistentes de programação. Ele não exige GitHub Spec Kit, mas os artefatos podem ser adaptados à ferramenta escolhida.

## Regra principal

**Especificar → revisar → planejar → revisar → decompor em tarefas → implementar uma tarefa → testar → verificar → atualizar os documentos.**

Não solicite que a IA gere o sistema inteiro de uma vez.

## Etapa 0 — Preparar o material

1. Guarde a apresentação original e os diagramas em uma pasta de referência.
2. Leia o `AGENTS.md` e verifique quais documentos de planejamento, especificação e constituição estão disponíveis.
3. Identifique documentos ausentes, questões abertas e contradições sem presumir respostas.
4. Confirme com a equipe quais partes serão reais, simuladas ou ficarão fora do escopo do protótipo.

Prompt:

> Leia o AGENTS.md e todos os documentos relevantes disponíveis. Não escreva código. Liste os materiais encontrados, os documentos ausentes, as contradições, as dúvidas e as decisões necessárias para definir o escopo do protótipo. Identifique o documento ou diagrama relacionado a cada dúvida. Não invente respostas.

## Etapa 1 — Aprovar a especificação

Revise os requisitos funcionais, requisitos não funcionais e critérios de aceitação em `spec.md`.

Prompt:
> Revise a especificação usando somente o planejamento aprovado. Para cada requisito, indique a origem, os critérios de aceitação e as informações pendentes. Não altere o escopo sem apresentar a proposta de mudança. Não implemente código.

**Gate:** a equipe aprova os requisitos e resolve as questões essenciais.

## Etapa 2 — Aprovar o plano técnico

Prompt:
> Com base na especificação aprovada e nos diagramas, proponha a arquitetura mínima que satisfaça os requisitos do protótipo. Separe componentes reais, simulados e fora do escopo. Liste módulos, contratos, dependências, riscos e testes. Não implemente código e não escolha tecnologias ainda não aprovadas. Diferencie tecnologias explicitamente indicadas nos materiais de tecnologias apenas sugeridas. Não trate nomes presentes nos diagramas como decisões definitivas de implementação sem confirmação da equipe.

**Gate:** a equipe aprova linguagem, arquitetura, tecnologias e estratégia de testes.

## Etapa 3 — Gerar e revisar tarefas

Prompt:
> Converta o plano aprovado em tarefas pequenas, ordenadas por dependências. Cada tarefa deve indicar objetivo, arquivos esperados, requisitos atendidos, testes e critério de conclusão. Não inclua tarefas que dependam de decisões pendentes. Não implemente código.

**Gate:** as tarefas são compreensíveis e verificáveis.

## Etapa 4 — Implementar uma tarefa por vez

Prompt:
> Implemente somente a tarefa indicada pelo usuário. Consulte o AGENTS.md e os documentos relevantes disponíveis. Se existir uma tarefa correspondente em tasks.md, siga seu escopo e seus critérios de conclusão. Se não existir, defina o objetivo, os arquivos envolvidos, os critérios de aceitação e os testes antes de implementar. Não implemente funcionalidades adicionais. Se faltar uma informação essencial ou for necessária uma mudança de requisito ou arquitetura, explique a situação antes de prosseguir. Execute os testes pertinentes e informe os resultados reais.

Após cada tarefa:
1. Revise o diff/arquivos alterados.
2. Execute os testes.
3. Confira os critérios de aceitação.
4. Atualize `tasks.md` somente com base em evidências.
5. Atualize os documentos se uma mudança aprovada exigir isso.

## Etapa 5 — Verificação independente

Prompt:
> Verifique a implementação contra cada critério de aceitação da especificação. Não presuma que o código está correto. Execute os testes disponíveis e crie uma tabela com requisito, evidência, resultado (passou/falhou/não verificado) e pendências. Não declare aprovado o que não foi testado.

## Etapa 6 — Encerrar incremento

Só encerre um incremento quando:
- os testes relacionados forem executados;
- os critérios de aceitação forem conferidos;
- falhas e limitações forem documentadas;
- a implementação corresponder à especificação aprovada;
- os arquivos de documentação estiverem atualizados.

## Controle de mudanças

Quando surgir uma necessidade que altere requisitos ou arquitetura:

1. Registrar a mudança proposta.
2. Explicar sua justificativa e seus impactos.
3. Identificar os documentos afetados, como `spec.md`, `plan.md`, `tasks.md` e os diagramas.
4. Solicitar aprovação antes de realizar a alteração de requisito ou arquitetura.
5. Atualizar os documentos aprovados e só então implementar a mudança.

Correções internas que preservem os requisitos e a arquitetura aprovados podem ser realizadas normalmente, desde que respeitem o escopo da tarefa.

## Se usar GitHub Spec Kit

O Spec Kit possui seus próprios comandos e convenções. Antes de adotá-lo, siga a documentação oficial da versão instalada e mapeie os artefatos existentes para os arquivos exigidos pela ferramenta. Não copie comandos de versões diferentes sem verificar.
