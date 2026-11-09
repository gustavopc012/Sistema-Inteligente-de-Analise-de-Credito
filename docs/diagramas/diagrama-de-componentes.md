# Diagrama de Componentes — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento descreve as camadas, os componentes, as portas e os relacionamentos identificados no diagrama de componentes do Sistema Inteligente de Análise de Crédito.

O objetivo é documentar as conexões representadas graficamente, preservando as informações do diagrama original.

O diagrama apresenta dois atores externos e cinco agrupamentos: Interface, Aplicação, Domínio, Portas e Infraestrutura. As conexões aparecem como setas contínuas e tracejadas, algumas com rótulos.

## 2. Camadas e componentes

### 2.1. Atores externos

**Elementos identificados:**

- **Cliente:** conectado ao Credito Controller por uma seta contínua.
- **Analista:** conectado ao Analista Controller por uma seta contínua.

### 2.2. Interface

Agrupamento identificado com a indicação `<<Interface>>`.

**Componentes identificados:**

- **Credito Controller:** recebe a conexão do Cliente.
- **Analista Controller:** recebe a conexão do Analista.

**Relacionamentos representados:**

- Credito Controller → Processar Solicitação (seta tracejada, sem rótulo).
- Analista Controller → Avaliar Proposta Condicional (seta tracejada, sem rótulo).

### 2.3. Aplicação

Agrupamento identificado com a indicação `<<Aplicação>>`.

**Componentes identificados:**

- **Processar Solicitação (Pipeline Multimodal):** componente com o maior número de conexões de saída do diagrama.
- **Avaliar Proposta Condicional:** recebe a conexão do Analista Controller.

**Relacionamentos representados a partir de Processar Solicitação (setas tracejadas):**

- `1.avaliar contexto` → Circuit Breaker.
- `2.isolar_anomalia` → Motor Anti-Fraude.
- `3.calcular_target` → Motor Scoring.
- `4.extrair_sharp` → Gerador de Parecer.
- `buscar_perfil` → porta Feature Store.

O diagrama não apresenta conexões de saída a partir de Avaliar Proposta Condicional.

### 2.4. Domínio

Agrupamento identificado com a indicação `<<Dominio>>` e o título "Dominio (Core IA & Regras)".

**Componentes identificados:**

- **Circuit Breaker (Segurança Macro).**
- **Motor Anti-Fraude (Clustering).**
- **Motor Scoring (XGBoost).**
- **Gerador de Parecer (Valores SHARP).**

**Relacionamentos representados (setas tracejadas):**

- Motor Anti-Fraude → porta Modelo ML, com o rótulo `inferir`.
- Motor Scoring → porta Modelo ML, com o rótulo `inferir`.
- Gerador de Parecer → porta Auditoria XAI, com o rótulo `salvar_justificativa`.

O diagrama não apresenta conexões de saída a partir do Circuit Breaker.

### 2.5. Portas

Agrupamento identificado com o título "Portas - behavious do Dominio". Cada porta está marcada com a indicação `<<Porta>>` e representada por um círculo.

**Portas identificadas:**

- **Modelo ML:** recebe as conexões `inferir` do Motor Anti-Fraude e do Motor Scoring.
- **Auditoria XAI:** recebe a conexão `salvar_justificativa` do Gerador de Parecer.
- **Feature Store:** recebe a conexão `buscar_perfil` de Processar Solicitação.

A imagem não especifica as operações, os parâmetros ou os retornos de cada porta.

### 2.6. Infraestrutura

Agrupamento identificado com a indicação `<<INFRA>>`.

**Componentes identificados:**

- **NX / Bumblebee (Erlang/GPU):** conectado à porta Modelo ML.
- **Adaptador Postgres (Cold Storage):** conectado à porta Auditoria XAI.
- **Adaptador Redis (Tensores In-Memory):** conectado à porta Feature Store.

**Relacionamentos representados:**

- As três conexões são setas contínuas que partem dos componentes da Infraestrutura e apontam para as portas.

O diagrama não detalha como cada componente de infraestrutura atende à sua porta.

## 3. Relacionamentos entre os componentes

As conexões visíveis no diagrama indicam o seguinte fluxo geral:

1. O Cliente acessa o Credito Controller, que se conecta a Processar Solicitação.
2. O Analista acessa o Analista Controller, que se conecta a Avaliar Proposta Condicional.
3. Processar Solicitação se conecta, com rótulos numerados de 1 a 4, ao Circuit Breaker, ao Motor Anti-Fraude, ao Motor Scoring e ao Gerador de Parecer.
4. Processar Solicitação se conecta à porta Feature Store (`buscar_perfil`).
5. O Motor Anti-Fraude e o Motor Scoring se conectam à porta Modelo ML (`inferir`).
6. O Gerador de Parecer se conecta à porta Auditoria XAI (`salvar_justificativa`).
7. NX / Bumblebee, Adaptador Postgres e Adaptador Redis se conectam, respectivamente, às portas Modelo ML, Auditoria XAI e Feature Store.

Essas conexões documentam as direções representadas graficamente. A imagem, isoladamente, não permite determinar os contratos, os dados trocados ou o comportamento em caso de falha.

## 4. Resumo das camadas e componentes

| Agrupamento | Componentes identificados |
|---|---|
| Atores externos | Cliente; Analista |
| Interface | Credito Controller; Analista Controller |
| Aplicação | Processar Solicitação (Pipeline Multimodal); Avaliar Proposta Condicional |
| Domínio | Circuit Breaker; Motor Anti-Fraude; Motor Scoring; Gerador de Parecer |
| Portas | Modelo ML; Auditoria XAI; Feature Store |
| Infraestrutura | NX / Bumblebee; Adaptador Postgres; Adaptador Redis |

| Porta | Componentes que a utilizam | Componente de infraestrutura conectado |
|---|---|---|
| Modelo ML | Motor Anti-Fraude; Motor Scoring | NX / Bumblebee |
| Auditoria XAI | Gerador de Parecer | Adaptador Postgres |
| Feature Store | Processar Solicitação | Adaptador Redis |

## 5. Pontos a esclarecer

Os seguintes pontos podem exigir confirmação com a equipe ou consulta ao planejamento original:

1. **SHARP x SHAP:** o diagrama usa "Valores SHARP" e `4.extrair_sharp`, enquanto o documento de casos de uso usa "Valores SHAP". Confirmar se se trata do mesmo conceito e padronizar o nome.
2. **Limiares de decisão:** o diagrama de pacotes apresenta um Otimizador de Thresholds, e o diagrama de sequência apresenta "Limiares de Decisão", mas nenhum dos dois aparece neste diagrama. Confirmar em qual componente essa etapa está representada.
3. **Monitor de Estabilidade:** o pacote MLOps (Assíncrono) e o caso de uso Monitorar Estabilidade não têm componente correspondente neste diagrama.
4. **Ordem dos passos:** confirmar se os rótulos 1 a 4 indicam execução sequencial e o que ocorre quando uma etapa interrompe o processo.
5. **Circuit Breaker:** o componente não possui conexão com nenhuma porta. Identificar de onde vêm os dados usados para avaliar o contexto.
6. **Avaliar Proposta Condicional:** o componente não possui conexões de saída. Esclarecer como a decisão do analista é registrada.
7. **calcular_target:** esclarecer o significado operacional do rótulo.
8. **Nomes das camadas:** o diagrama de pacotes usa outros agrupamentos (Ingestão Multimodal, Segurança Sistêmica, Core IA, Decisão e Conformidade, MLOps). Confirmar a correspondência entre os dois diagramas.
9. **Tecnologias:** confirmar se XGBoost, NX / Bumblebee, Postgres e Redis são tecnologias aprovadas para o protótipo ou apenas indicações do diagrama.
10. **Portas como behaviours:** o título do agrupamento menciona behaviours. Confirmar se as portas serão implementadas dessa forma.

Esses pontos são questões em aberto, e não decisões confirmadas pelo diagrama.

## 6. Limites deste documento

Este documento registra as camadas, os componentes, as portas e os relacionamentos identificados na imagem.

Ele não define, por conta própria:

- tecnologias definitivas de implementação;
- nomes de módulos, funções ou contratos de código;
- formatos dos dados trocados entre os componentes;
- regras de aprovação ou reprovação de crédito;
- limites numéricos ou parâmetros dos modelos;
- comportamento em caso de falha.

Essas informações devem ser obtidas dos documentos de planejamento e das especificações aprovadas pela equipe.

## 7. Referência

**Fonte:** Diagrama de Componentes — Sistema Inteligente de Análise de Crédito, fornecido pela equipe do projeto.
