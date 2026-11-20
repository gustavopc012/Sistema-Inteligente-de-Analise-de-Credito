# Sistema Inteligente de Análise de Crédito

Projeto acadêmico da **Equipe Omicron**, desenvolvido no contexto da disciplina de CLP

O **Sistema Inteligente de Análise de Crédito** tem como objetivo apoiar a avaliação de propostas de crédito por meio do processamento de dados de diferentes fontes, da aplicação de técnicas de aprendizado de máquina e da geração de explicações que auxiliem a análise dos resultados.

**Linguagem de programação:** Elixir.

> **Status do projeto:** núcleo do MVP concluído e verificado em 19/11/2026 (`docs/verificacao-mvp.md`), com 92 testes aprovados. Em 20/11/2026, foi adicionada a interface web de demonstração (T10), descrita em `credit_engine/README.md`. O projeto conta atualmente com 108 testes, sem falhas registradas, e os cinco cenários do `plan.md` podem ser demonstrados pelo `iex` ou pela interface web.

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
- **GenServer (OTP):** usado no Circuit Breaker (tarefa T2), supervisionado pela aplicação.
- **`:httpd` (Erlang/OTP):** servidor da interface web de demonstração (tarefa T10). Já vem com o Erlang, sem dependência externa.

### Tecnologias da arquitetura final (diagramas)

Os documentos de arquitetura também mencionam Phoenix, NX/Bumblebee, XGBoost, Redis, PostgreSQL, NGINX e Kubernetes, além de alternativas de algoritmos como Isolation Forest e K-Means.

Essas tecnologias formam a arquitetura final do sistema. Para o MVP, a equipe decidiu em 17/11/2026 implementar o núcleo em Elixir puro (Mix, ExUnit e GenServer), mantendo cada etapa em um módulo próprio, que é o ponto em que a tecnologia de produção seria conectada. A correspondência entre cada componente do diagrama e o que entra no MVP está no `plan.md`, seção 3.

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
| `plan.md` | Plano técnico do MVP: escopo, tecnologias, contratos, valores de demonstração e cronograma. | No repositório |
| `tasks.md` | Tarefas do MVP, com dependências, testes, critérios de conclusão e responsáveis. | No repositório |
| `spec.md` | Especificação do incremento "Recebimento e validação de propostas". | No repositório (aguardando aprovação) |
| `docs/verificacao-incremento-01.md` | Verificação do incremento 1 contra os critérios de aceitação do `spec.md`. | No repositório |
| `docs/verificacao-mvp.md` | Verificação do MVP contra o `plan.md`: requisito, evidência e resultado. | No repositório |
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

**Concluído:**

- Documentação, diagramas e fluxo SDD no repositório.
- Incremento 1: recebimento e validação de propostas (`spec.md`), com verificação em `docs/verificacao-incremento-01.md`.
- Definição do MVP (`plan.md`) e divisão em tarefas (`tasks.md`).
- T0: configuração dos valores de demonstração (`credit_engine/config/config.exs`).
- T2: Circuit Breaker.
- T3: detecção de anomalias.
- T4: score de risco.
- T5: limiares de decisão.
- T6: parecer explicável.
- T7: pipeline completo (`CreditEngine.analisar/1`).
- T8: cinco cenários de ponta a ponta e demonstração pelo `iex` (comandos em `credit_engine/README.md`).
- T9: verificação final do MVP (`docs/verificacao-mvp.md`).
- T10: interface web de demonstração (`mix credit_engine.web`, em http://localhost:4000). Detalhes no `plan.md`, seção 13.

**Próximas etapas (`plan.md`, seção 11):** correções e roteiro da demonstração (21 e 22/11), ensaio (23/11) e evento final (24/11).

**Decidido para o MVP em 17/11/2026:** escopo, tecnologias, contratos entre as etapas, formato do parecer e valores de demonstração do Circuit Breaker, das anomalias, do score e dos limiares. Os valores servem para a demonstração e não estão calibrados com dados reais.

**Ainda em aberto:** entre outros pontos, a recuperação do Circuit Breaker, a calibração dos limiares, os algoritmos de produção, o monitoramento e o retreinamento dos modelos, a avaliação de equidade e a persistência das propostas.

A relação completa, com o que foi decidido e o que continua em aberto, está em `docs/decisoes-pendentes.md`. Nenhum valor ou regra de decisão além do que está registrado ali e no `plan.md` deve ser considerado definitivo.

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
