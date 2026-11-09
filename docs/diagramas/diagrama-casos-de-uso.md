# Diagrama de Casos de Uso — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento descreve os atores, os casos de uso e os relacionamentos identificados no diagrama de casos de uso do Sistema Inteligente de Análise de Crédito.

O objetivo é documentar as funcionalidades representadas graficamente, preservando as informações do diagrama original.

## 2. Atores

### 2.1. Sistema ML Ops

Representa o sistema relacionado às operações e ao monitoramento do modelo de aprendizado de máquina.

**Interação identificada no diagrama:**
- Monitorar estabilidade do modelo.

### 2.2. Cliente

Representa o usuário que solicita uma análise de crédito.

**Interação identificada no diagrama:**
- Solicitar análise de crédito.

### 2.3. Analista de Crédito

Representa o profissional que interage com o sistema para analisar propostas em situações de incerteza.

**Interação identificada no diagrama:**
- Analisar proposta em zona de incerteza.

### 2.4. Administrador de Risco

Representa o responsável pelas atividades de calibração de limiares e verificação do mecanismo de proteção do sistema.

**Interações identificadas no diagrama:**
- Calibrar limiares (thresholds/matriz de confusão).
- Verificar disjuntor (circuit breaker).

### 2.5. Fontes de Dados Open Finance

Representa as fontes externas de dados identificadas no diagrama.

**Interação identificada no diagrama:**
- Ingestão de dados.

## 3. Casos de uso

### 3.1. Monitorar Estabilidade (Data Drift/PSI)

Representa o monitoramento da estabilidade do modelo, considerando os conceitos de *data drift* e PSI (Population Stability Index).

O diagrama relaciona este caso de uso ao Sistema ML Ops.

**Relacionamento identificado:**
- `<<include>>` — Retreinamento por IA (SHARP).

### 3.2. Retreinamento por IA (SHARP)

Representa o processo de retreinamento do modelo indicado no diagrama.

Está relacionado ao caso de uso Monitorar Estabilidade por meio de `<<include>>`.

A imagem não detalha o funcionamento interno do retreinamento nem esclarece o significado de SHARP.

### 3.3. Solicitar Análise de Crédito

Representa a solicitação de uma análise de crédito pelo cliente.

O diagrama relaciona esta funcionalidade a outros casos de uso que participam do processo de análise.

**Relacionamentos identificados:**
- `<<include>>` — Calcula Score de Risco (Supervisionado).
- `<<include>>` — Detecta Fraude Comportamental (Clustering).
- `<<include>>` — Gera Parecer Explicável (Valores SHAP).
- `<<extend>>` — Analisa Proposta em Zona de Incerteza, sob a condição indicada no diagrama: `SE SCORE = INDEFINIDO`.
- `<<include>>` — Verificar Disjuntor (Circuit Breaker).
- `<<include>>` — Ingestão de Dados.

### 3.4. Calcula Score de Risco (Supervisionado)

Representa o cálculo de uma pontuação de risco por meio de um modelo supervisionado.

O diagrama indica que este caso de uso está incluído em Solicitar Análise de Crédito.

### 3.5. Detecta Fraude Comportamental (Clustering)

Representa a detecção de possíveis fraudes comportamentais por meio de técnicas de agrupamento (*clustering*).

O diagrama indica que este caso de uso está incluído em Solicitar Análise de Crédito.

### 3.6. Gera Parecer Explicável (Valores SHAP)

Representa a geração de um parecer explicável utilizando valores SHAP (*SHapley Additive exPlanations*).

O diagrama indica que este caso de uso está incluído em Solicitar Análise de Crédito.

### 3.7. Analisa Proposta em Zona de Incerteza

Representa a análise de uma proposta de crédito em uma situação de incerteza.

O caso de uso está associado ao ator Analista de Crédito.

O diagrama indica um relacionamento `<<extend>>` com Solicitar Análise de Crédito, condicionado à situação descrita como `SE SCORE = INDEFINIDO`.

### 3.8. Verificar Disjuntor (Circuit Breaker)

Representa a verificação do mecanismo denominado *circuit breaker*.

O diagrama associa este caso de uso ao Administrador de Risco e indica sua inclusão no processo de Solicitar Análise de Crédito.

### 3.9. Ingestão de Dados

Representa a entrada de dados no sistema.

O diagrama associa este caso de uso às Fontes de Dados Open Finance e indica sua inclusão no processo de Solicitar Análise de Crédito.

### 3.10. Calibrar Limiares (Thresholds/Matriz de Confusão)

Representa a calibração de limiares e a utilização de uma matriz de confusão, conforme indicado no nome do caso de uso.

O diagrama associa esta funcionalidade ao Administrador de Risco.

A imagem não especifica os limiares utilizados nem os procedimentos de calibração.

## 4. Relacionamentos

### 4.1. Relacionamentos entre atores e casos de uso

| Ator | Caso de uso associado |
|---|---|
| Sistema ML Ops | Monitorar Estabilidade (Data Drift/PSI) |
| Cliente | Solicitar Análise de Crédito |
| Analista de Crédito | Analisar Proposta em Zona de Incerteza |
| Administrador de Risco | Calibrar Limiares (Thresholds/Matriz de Confusão) |
| Administrador de Risco | Verificar Disjuntor (Circuit Breaker) |
| Fontes de Dados Open Finance | Ingestão de Dados |

### 4.2. Relacionamentos `<<include>>`

O diagrama apresenta os seguintes relacionamentos de inclusão:

| Caso de uso de origem | Caso de uso relacionado |
|---|---|
| Monitorar Estabilidade (Data Drift/PSI) | Retreinamento por IA (SHARP) |
| Solicitar Análise de Crédito | Calcula Score de Risco (Supervisionado) |
| Solicitar Análise de Crédito | Detecta Fraude Comportamental (Clustering) |
| Solicitar Análise de Crédito | Gera Parecer Explicável (Valores SHAP) |
| Solicitar Análise de Crédito | Verificar Disjuntor (Circuit Breaker) |
| Solicitar Análise de Crédito | Ingestão de Dados |

### 4.3. Relacionamento `<<extend>>`

O diagrama apresenta o seguinte relacionamento de extensão:

| Caso de uso de origem | Caso de uso estendido | Condição indicada |
|---|---|---|
| Analisar Proposta em Zona de Incerteza | Solicitar Análise de Crédito | Se o score for indefinido |

A condição acima reproduz a indicação textual da imagem. A regra operacional exata para determinar quando um score é considerado indefinido não está especificada no diagrama.

## 5. Observações e pontos a esclarecer

Os seguintes pontos precisam ser confirmados com base no planejamento original ou com a equipe do projeto:

1. **SHARP:** confirmar o significado da sigla e o procedimento de retreinamento representado.
2. **Score indefinido:** esclarecer quais situações caracterizam um score indefinido e como a proposta deve ser encaminhada para análise humana.
3. **Matriz de confusão e limiares:** esclarecer como a calibração será realizada e quais critérios serão utilizados.
4. **Circuit breaker:** definir seu comportamento esperado, as condições de acionamento e o procedimento de recuperação, caso essas informações sejam necessárias para a implementação.
5. **Ingestão de dados:** identificar quais dados serão obtidos das fontes Open Finance e como serão tratados.
6. **Monitoramento de estabilidade:** esclarecer como o data drift e o PSI serão calculados e quais condições poderão iniciar o retreinamento.

Esses pontos são questões em aberto identificadas a partir do diagrama. Não representam requisitos já aprovados.

## 6. Limites deste documento

Este documento descreve os elementos identificados no diagrama de casos de uso.

Ele não define, por conta própria:

- regras de negócio para aprovação ou reprovação de crédito;
- fórmulas ou pesos para cálculo do score;
- limites numéricos de risco;
- algoritmos específicos além dos conceitos mencionados nos nomes dos casos de uso;
- tecnologias definitivas de implementação;
- contratos de API ou estruturas de banco de dados.

Essas definições devem ser obtidas dos documentos de planejamento e da especificação aprovada pelo projeto.

## 7. Referência

**Fonte:** Diagrama de Casos de Uso — Sistema Inteligente de Análise de Crédito, fornecido pela equipe do projeto.