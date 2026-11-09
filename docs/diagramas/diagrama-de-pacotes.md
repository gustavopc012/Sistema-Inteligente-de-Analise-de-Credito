# Diagrama de Pacotes — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento descreve a organização modular do Sistema Inteligente de Análise de Crédito, conforme representado no diagrama de pacotes fornecido pela equipe.

O diagrama apresenta cinco pacotes principais, seus componentes internos e os relacionamentos representados por setas contínuas e tracejadas.

## 2. Pacotes do sistema

### 2.1. Ingestão Multimodal

Pacote responsável pelos componentes relacionados à entrada e à integração inicial dos dados.

**Componentes identificados:**

- **API Gateway:** componente representado como ponto de entrada do fluxo.
- **Feature Store Integrator:** componente identificado com a indicação `<<MICROSSEGUNDOS>>`, conforme o diagrama.

**Relacionamento representado:**

- API Gateway → Feature Store Integrator.
- Feature Store Integrator → Circuit Breaker, no pacote Segurança Sistêmica.

O diagrama não detalha os formatos dos dados recebidos, os protocolos de comunicação ou o funcionamento interno do integrador.

### 2.2. Segurança Sistêmica

Pacote que contém o mecanismo identificado como disjuntor de proteção.

**Componente identificado:**

- **Circuit Breaker:** componente marcado com a indicação `<<DISJUNTOR MACRO>>`.

**Relacionamentos representados:**

- Recebe uma conexão proveniente do Feature Store Integrator.
- Possui uma conexão direcionada ao componente de detecção de anomalias, no pacote Core IA.

A imagem não especifica as condições de acionamento do Circuit Breaker, os limites utilizados ou o procedimento de recuperação.

### 2.3. Core IA

Pacote que reúne os componentes relacionados ao processamento e à análise por inteligência artificial.

**Componentes identificados:**

#### Aprendizado não supervisionado

Representa o grupo relacionado ao aprendizado não supervisionado.

- **Detecção de Anomalias (Isolation Forest/K-Means):** componente que indica o uso de técnicas de detecção de anomalias e agrupamento.

O diagrama apresenta uma conexão entre o Circuit Breaker e a Detecção de Anomalias.

#### Aprendizado supervisionado

Representa o grupo relacionado ao aprendizado supervisionado.

- **Motor Preditivo (XGBoost/DNNs):** componente responsável pela etapa preditiva indicada no planejamento.

O diagrama apresenta uma conexão da Detecção de Anomalias para o Motor Preditivo.

O nome do componente menciona XGBoost e DNNs, mas a imagem não esclarece se ambos serão utilizados simultaneamente ou se representam alternativas de implementação.

### 2.4. Decisão e Conformidade

Pacote relacionado à otimização dos limiares de decisão e à geração de explicações associadas às decisões do sistema.

**Componentes identificados:**

- **Otimizador de Thresholds:** componente conectado ao Motor Preditivo.
- **Motor XAI (Valores SHAP e Fairness):** componente relacionado à explicabilidade e à avaliação de aspectos de equidade.

**Relacionamentos representados:**

- Motor Preditivo → Otimizador de Thresholds.
- Otimizador de Thresholds → Motor XAI.

A imagem não especifica os critérios de otimização, os valores dos limiares ou as métricas de equidade que serão utilizadas.

### 2.5. MLOps (Assíncrono)

Pacote relacionado ao monitoramento operacional dos modelos de aprendizado de máquina.

**Componente identificado:**

- **Monitor de Estabilidade:** componente representado dentro do pacote MLOps (Assíncrono).

O diagrama apresenta uma conexão tracejada entre o Monitor de Estabilidade e o Motor Preditivo.

A imagem não detalha a periodicidade do monitoramento, os indicadores utilizados ou as ações executadas quando uma instabilidade é identificada.

## 3. Relacionamentos entre os componentes

As conexões visíveis no diagrama indicam o seguinte fluxo geral:

1. O API Gateway está conectado ao Feature Store Integrator.
2. O Feature Store Integrator está conectado ao Circuit Breaker.
3. O Circuit Breaker está conectado à Detecção de Anomalias.
4. A Detecção de Anomalias está conectada ao Motor Preditivo.
5. O Motor Preditivo está conectado ao Otimizador de Thresholds.
6. O Otimizador de Thresholds está conectado ao Motor XAI.
7. O Monitor de Estabilidade possui uma conexão tracejada com o Motor Preditivo.

Essas conexões documentam as direções representadas graficamente. A imagem, isoladamente, não permite determinar todos os detalhes dos contratos, dos protocolos ou da execução interna desses componentes.

## 4. Resumo dos pacotes e componentes

| Pacote | Componentes identificados |
|---|---|
| Ingestão Multimodal | API Gateway; Feature Store Integrator |
| Segurança Sistêmica | Circuit Breaker |
| Core IA | Detecção de Anomalias; Motor Preditivo |
| Decisão e Conformidade | Otimizador de Thresholds; Motor XAI |
| MLOps (Assíncrono) | Monitor de Estabilidade |

## 5. Pontos a esclarecer

Os seguintes pontos podem exigir confirmação com a equipe ou consulta ao planejamento original:

1. **Microssegundos:** esclarecer o significado da indicação associada ao Feature Store Integrator e se ela representa uma meta de latência.
2. **Circuit Breaker:** identificar as condições de acionamento e o comportamento esperado em caso de falha.
3. **Algoritmos de IA:** confirmar se Isolation Forest, K-Means, XGBoost e DNNs são tecnologias aprovadas ou alternativas ainda em avaliação.
4. **Otimizador de Thresholds:** identificar os critérios utilizados para definir os limiares de decisão.
5. **Motor XAI:** esclarecer como serão produzidas as explicações com SHAP e como será avaliada a equidade (*fairness*).
6. **MLOps assíncrono:** esclarecer o significado operacional da conexão tracejada entre o monitor e o motor preditivo.
7. **Ingestão multimodal:** identificar quais modalidades de dados serão efetivamente utilizadas pelo sistema.

Esses pontos são questões em aberto, e não decisões confirmadas pelo diagrama.

## 6. Limites deste documento

Este documento registra os pacotes, os componentes e os relacionamentos identificados na imagem.

Ele não define, por conta própria:

- tecnologias definitivas de implementação;
- linguagens de programação ou frameworks;
- contratos de API;
- estruturas de banco de dados;
- parâmetros dos algoritmos;
- regras de aprovação de crédito;
- requisitos de desempenho não especificados.

Essas informações devem ser obtidas dos documentos de planejamento e das especificações aprovadas pela equipe.

## 7. Referência

**Fonte:** Diagrama de Pacotes — Sistema Inteligente de Análise de Crédito, fornecido pela equipe do projeto.