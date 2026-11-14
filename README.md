# Sistema Inteligente de Análise de Crédito

Projeto acadêmico da **Equipe Omicron**, desenvolvido no contexto da disciplina de CLP

O **Sistema Inteligente de Análise de Crédito** tem como objetivo apoiar a avaliação de propostas de crédito por meio do processamento de dados de diferentes fontes, da aplicação de técnicas de aprendizado de máquina e da geração de explicações que auxiliem a análise dos resultados.

**Linguagem de programação:** Elixir.

> **Status do projeto:** planejamento e documentação em consolidação, com início da implementação incremental. Algumas regras de negócio, parâmetros dos modelos e decisões complementares de arquitetura ainda dependem de definição e aprovação da equipe.

## Objetivos

- Organizar e processar dados relacionados às propostas de crédito.
- Estruturar um fluxo de análise que contemple dados multimodais e informações de Open Finance.
- Estimar o risco de inadimplência por meio de técnicas de aprendizado de máquina.
- Identificar possíveis anomalias ou comportamentos suspeitos.
- Produzir explicações rastreáveis que apoiem a compreensão dos resultados.
- Prever mecanismos de monitoramento da estabilidade dos modelos e de revisão humana em situações de incerteza.

## Visão geral da solução

A arquitetura documentada organiza o sistema em cinco áreas principais:

| Área | Responsabilidade prevista |
|---|---|
| **Ingestão Multimodal** | Receber e integrar os dados necessários à análise. |
| **Segurança Sistêmica** | Verificar o mecanismo Circuit Breaker relacionado ao contexto macroeconômico. |
| **Core IA** | Reunir as etapas de detecção de anomalias e previsão de risco. |
| **Decisão e Conformidade** | Tratar os critérios de decisão e a explicabilidade dos resultados. |
| **MLOps (Assíncrono)** | Acompanhar a estabilidade dos modelos e aspectos relacionados ao monitoramento. |

O fluxo planejado parte da solicitação de análise, passa pela ingestão e pelas verificações previstas, executa as etapas de análise e encaminha o resultado para classificação e geração de parecer. Propostas em situações de incerteza poderão ser encaminhadas para análise humana, conforme regras que serão formalizadas pela equipe.

## Funcionalidades previstas

Com base nos diagramas e documentos de planejamento, o sistema contempla:

- Solicitação de análise de crédito.
- Ingestão de dados, incluindo fontes associadas ao Open Finance.
- Estimativa de risco por modelo supervisionado.
- Detecção de anomalias ou possíveis fraudes por técnicas não supervisionadas.
- Verificação de Circuit Breaker.
- Classificação de propostas conforme critérios de decisão.
- Geração de parecer explicável, com referência a SHAP.
- Encaminhamento de propostas em zona de incerteza para análise humana.
- Monitoramento da estabilidade dos modelos, incluindo referências a Data Drift e PSI.

Essas funcionalidades representam o escopo planejado; não significam que já estejam implementadas.

## Tecnologias

### Linguagem definida

- **Elixir:** linguagem de programação do projeto.
- **Mix e ExUnit:** estrutura do projeto e testes automatizados, em uso na pasta `credit_engine/`. O projeto não possui dependências externas nesta etapa.

### Tecnologias e ferramentas previstas nos diagramas

Os documentos de arquitetura também mencionam Phoenix, NX/Bumblebee, XGBoost, Redis, PostgreSQL, NGINX e Kubernetes, além de alternativas de algoritmos como Isolation Forest e K-Means.

A presença dessas tecnologias nos diagramas registra o planejamento atual, mas não significa que todas já estejam confirmadas para a implementação. A equipe deverá documentar as escolhas complementares e eventuais alternativas antes de utilizá-las no projeto.

## Estrutura da documentação

Os documentos de planejamento e arquitetura são mantidos junto ao código-fonte, na seguinte organização:

| Arquivo | Conteúdo | Situação |
|---|---|---|
| `AGENTS.md` | Orientações para assistentes de programação e regras de implementação. | No repositório |
| `CLAUDE.md` | Ponto de entrada do Claude Code; direciona para o `AGENTS.md` e para a documentação. | No repositório |
| `docs/fluxo-sdd.md` | Fluxo de trabalho baseado em Spec-Driven Development. | No repositório |
| `docs/decisoes-pendentes.md` | Registro de conflitos, lacunas e decisões que precisam de aprovação. | No repositório |
| `docs/diagramas/diagrama-casos-de-uso.md` | Atores e funcionalidades representados no diagrama de casos de uso. | No repositório |
| `docs/diagramas/diagrama-de-pacotes.md` | Organização dos pacotes e seus componentes. | No repositório |
| `docs/diagramas/diagrama-de-componentes.md` | Componentes, camadas, portas e dependências. | No repositório |
| `docs/diagramas/diagrama-de-classes.md` | Estruturas, atributos e operações representados no diagrama de classes. | No repositório |
| `docs/diagramas/diagrama-de-implantacao.md` | Nós e comunicações previstos para implantação. | No repositório |
| `docs/diagramas/sequencia.md` | Fluxo de interação e processamento representado no diagrama de sequência. | No repositório |
| `spec.md` | Especificação do incremento "Recebimento e validação de propostas". | No repositório (aguardando aprovação) |
| `docs/verificacao-incremento-01.md` | Verificação do incremento 1 contra os critérios de aceitação do `spec.md`. | No repositório |
| `credit_engine/` | Projeto Elixir (Mix), com código-fonte, testes e instruções próprias em `credit_engine/README.md`. | No repositório |

O `AGENTS.md` e o `CLAUDE.md` ficam na raiz porque é o local em que os assistentes de programação os procuram.

Para compilar e testar o projeto:

```bash
cd credit_engine
mix compile
mix test
```

As especificações e os planos de cada incremento, como `spec.md`, `plan.md` e `tasks.md`, serão criados ou atualizados conforme o fluxo SDD.

## Processo de desenvolvimento

O desenvolvimento seguirá uma abordagem incremental orientada por especificações (Spec-Driven Development):

1. **Especificar:** registrar o objetivo, os requisitos e os critérios de aceitação da funcionalidade.
2. **Revisar:** validar a especificação com a equipe e identificar decisões pendentes.
3. **Planejar:** definir a abordagem técnica e os arquivos que serão afetados.
4. **Dividir em tarefas:** organizar a implementação em etapas pequenas e verificáveis.
5. **Implementar:** desenvolver somente o escopo aprovado para a tarefa.
6. **Testar e verificar:** executar os testes e conferir os critérios de aceitação.
7. **Atualizar a documentação:** registrar alterações e decisões relevantes.

Tarefas independentes de decisões pendentes podem avançar. Regras de negócio ou escolhas arquiteturais ainda não definidas não devem ser inventadas durante a implementação.

## Situação atual e decisões pendentes

A documentação permite iniciar atividades preparatórias e incrementos técnicos bem delimitados, como a estrutura inicial do projeto Elixir, a configuração do ambiente de testes, a organização dos módulos e o uso de dados sintéticos.

Antes de implementar decisões definitivas de crédito, fraude ou risco sistêmico, a equipe precisa formalizar, entre outros pontos:

- Os estados possíveis de uma proposta e o significado de cada um.
- Os modelos e algoritmos que serão efetivamente utilizados.
- Os critérios e limiares de aprovação, recusa e análise manual.
- As condições de acionamento e recuperação do Circuit Breaker.
- O tratamento de propostas suspeitas, dados ausentes e falhas nas fontes.
- Os contratos de comunicação entre componentes.
- As tecnologias complementares e os critérios de monitoramento e retreinamento.

A relação consolidada está em `docs/decisoes-pendentes.md`. Nenhum valor de score, limite ou regra de decisão deve ser considerado definitivo sem aprovação da equipe.

## Diretrizes do projeto

- Utilizar Elixir como linguagem de programação.
- Utilizar dados sintéticos nos testes e exemplos.
- Não inserir dados pessoais reais de clientes no repositório.
- Não versionar senhas, tokens, chaves ou outras credenciais.
- Registrar falhas, dados ausentes e limitações relevantes.
- Não declarar testes como aprovados sem executá-los.
- Preservar requisitos e diagramas aprovados; propor mudanças de arquitetura separadamente.
- Manter rastreabilidade entre requisitos, tarefas, implementação e testes.

## Equipe

**Equipe:** Omicron  
**Disciplina/contexto:** CLP - Conceitos e Linguagens de Programação  
**Linguagem:** Elixir

---

*Este README apresenta a visão geral do projeto conforme a documentação de planejamento disponível. Deve ser atualizado à medida que a equipe aprovar decisões, concluir incrementos e validar funcionalidades.*
