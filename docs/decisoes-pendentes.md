# Decisões Pendentes — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento consolida os conflitos, as lacunas e as decisões que precisam de aprovação da equipe. Os itens foram reunidos a partir do `README.md`, do `spec.md`, das seções "Pontos a esclarecer" e "Pontos em aberto" dos diagramas e da verificação do incremento 1.

Nenhum item abaixo é uma decisão aprovada. Cada linha registra apenas a questão, onde ela aparece e o que depende dela.

## 2. Escopo e tecnologias

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP01 | Definir quais casos de uso e etapas do fluxo entram no MVP até 19/11. | Cronograma do monitor; `README.md` | Escrever `plan.md` e `tasks.md` |
| DP02 | Aprovar as tecnologias complementares do MVP. Os diagramas citam Phoenix, Nx/Bumblebee, XGBoost, DNNs, Redis, PostgreSQL, NGINX e Kubernetes. | `README.md`; `CLAUDE.md`; diagramas de componentes e de implantação | Adicionar qualquer dependência ao projeto |
| DP03 | Definir os algoritmos: Isolation Forest, K-Means ou DBSCAN para anomalias; XGBoost ou DNNs para o risco, e se são alternativas ou uso simultâneo. | Diagrama de pacotes (item 3); `sequencia.md`; diagrama de componentes (item 9) | Implementar a detecção de anomalias e o motor preditivo |
| DP04 | Definir quais partes do sistema serão reais, simuladas ou ficarão fora do escopo do protótipo. | `docs/fluxo-sdd.md` (Etapa 0); diagrama de implantação (item 10) | Plano técnico (Etapa 2 do SDD) |

## 3. Dados da proposta

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP05 | Definir a estrutura interna e as validações de cada mapa complementar (`applicant_data`, `open_finance_data`, `behavioral_data`, `macroeconomic_data`). | `spec.md` (seção 8); diagrama de classes | Qualquer etapa que leia esses dados |
| DP06 | Identificar quais dados virão das fontes Open Finance e como serão tratados. | Diagrama de casos de uso (item 5); diagrama de pacotes (item 7); `spec.md` | Ingestão de dados |
| DP07 | Definir o formato e a regra de unicidade do identificador da proposta. | `spec.md` (seção 8) | Persistência das propostas |
| DP08 | Definir o comportamento quando a entrada traz o mesmo campo como átomo e como texto (por exemplo, `:id` e `"id"`). | `docs/verificacao-incremento-01.md` (item 3) | Revisão do `spec.md` |
| DP09 | Definir os estados possíveis de uma proposta, seu significado, a persistência e o ciclo de vida. | `README.md`; `spec.md` (seção 8) | Registro e consulta de propostas |

## 4. Regras de decisão

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP10 | Definir o indicador macroeconômico, o limite de inadimplência, as condições de acionamento e o procedimento de recuperação do Circuit Breaker, e de onde vêm esses dados. | `README.md`; diagrama de pacotes (item 2); diagrama de casos de uso (item 4); `sequencia.md`; diagrama de componentes (item 5) | Implementar o Circuit Breaker |
| DP11 | Definir o limiar de distância que caracteriza fraude e o que acontece com a proposta em quarentena (apenas recusa ou fila de revisão). | `sequencia.md`; `README.md` | Implementar a detecção de fraude |
| DP12 | Definir as faixas de score que separam Aprovado, Condicional e Recusado e como a matriz de confusão será usada na calibração. O diagrama de sequência mostra apenas o exemplo `0,15`. | Diagrama de casos de uso (itens 2 e 3); diagrama de pacotes (item 4); `sequencia.md`; diagrama de classes (itens 8 e 10) | Implementar os limiares de decisão |
| DP13 | Definir quando uma proposta vai para análise humana (score indefinido) e como a decisão do analista é registrada. | Diagrama de casos de uso (item 2); diagrama de componentes (item 6) | Fluxo de análise condicional |
| DP14 | Definir o formato do parecer (texto livre ou estruturado), como os valores SHAP serão produzidos e traduzidos e como a equidade (*fairness*) será avaliada. | Diagrama de pacotes (item 5); `sequencia.md` | Implementar o parecer explicável |

## 5. Arquitetura e integração

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP15 | Definir os contratos de comunicação entre os componentes (entradas, saídas e erros de cada etapa). | `README.md`; diagrama de componentes (portas) | Integrar as etapas do fluxo |
| DP16 | Definir a estratégia para falhas: indisponibilidade de fontes, dados ausentes e tempo limite de um componente. | `sequencia.md`; `README.md` | Tratamento de erros no fluxo completo |
| DP17 | Resolver as diferenças entre diagramas: limiares e Monitor de Estabilidade ausentes no diagrama de componentes; nomes de camadas diferentes entre pacotes e componentes; camada de Aplicação sem lugar no diagrama de implantação; acesso dos workers ao perfil do cliente. | Diagrama de componentes (itens 2, 3 e 8); diagrama de implantação (itens 4 e 5) | Manter os diagramas coerentes com o código |
| DP18 | Definir como o *data drift* e o PSI serão calculados, o que dispara o retreinamento e o significado da conexão assíncrona entre o monitor e o motor preditivo. | Diagrama de casos de uso (item 6); diagrama de pacotes (item 6) | Monitoramento dos modelos |
| DP19 | Confirmar se a indicação "microssegundos" e a "leitura ultrarrápida" representam metas de latência e qual é o valor esperado. | Diagrama de pacotes (item 1); diagrama de implantação (item 8) | Requisitos não funcionais de desempenho |

## 6. Nomenclatura e correções nos diagramas

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP20 | Padronizar SHAP e SHARP. Os diagramas usam as duas formas. | Diagrama de casos de uso (item 1); diagrama de componentes (item 1); diagrama de classes (item 6) | Nomes de módulos e funções |
| DP21 | Decidir se o diagrama de classes será corrigido (atributo duplicado, `open finance` com espaço, `Credit.Engine` e `Compilance`, função dentro de `ParecerXAI`, `{error, :fraude}`) ou se a implementação passa a ser a referência. O código já usa `open_finance_data`, `behavioral_data` uma única vez e o prefixo `CreditEngine`. | Diagrama de classes (itens 1 a 5, 7 e 9) | Manter diagrama e código coerentes |
| DP22 | Corrigir as grafias "RCP" e "Kubernets" no diagrama de implantação. | Diagrama de implantação (itens 1 e 2) | Apresentação final |

## 7. Processo

| ID | Decisão necessária | Origem | Necessária para |
|---|---|---|---|
| DP23 | Aprovar o `spec.md` do incremento 1 (recebimento e validação de propostas). | `spec.md` (seção 9); `docs/verificacao-incremento-01.md` (item 1) | Encerrar o incremento 1 |
| DP24 | Decidir a adoção do Credo, previsto no quadro da equipe. | `docs/verificacao-incremento-01.md` (item 5); quadro do Trello | Configuração das ferramentas de qualidade |

## 8. Como registrar uma decisão

Quando a equipe aprovar um item:

1. Registrar a decisão neste documento, com a data e um resumo, e marcá-la como decidida.
2. Atualizar os documentos afetados (`spec.md`, `plan.md`, `tasks.md`, diagramas e `README.md`), conforme o controle de mudanças do `docs/fluxo-sdd.md`.
3. Só então implementar a mudança.

## 9. Referências

- `README.md`, seção "Situação atual e decisões pendentes".
- `spec.md`, seção 8.
- `docs/diagramas/`, seções "Pontos a esclarecer" e "Pontos em aberto".
- `docs/verificacao-incremento-01.md`, seção 8.
