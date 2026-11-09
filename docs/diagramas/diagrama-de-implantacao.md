# Diagrama de Implantação — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento descreve os nós, os ambientes, os artefatos e as comunicações identificados no diagrama de implantação do Sistema Inteligente de Análise de Crédito.

O objetivo é documentar a distribuição física representada graficamente, preservando as informações do diagrama original.

O diagrama apresenta três agrupamentos principais: o dispositivo do cliente, o ambiente de nuvem e o cluster de banco de dados. As comunicações aparecem como setas contínuas com rótulos.

## 2. Nós e ambientes

### 2.1. Dispositivo Cliente

Nó identificado com a indicação `<<frontend>>`.

**Artefato identificado:**

- **Aplicação WEB/MOBILE.**

**Comunicação representada:**

- Aplicação WEB/MOBILE → Gateway de Rede, com o rótulo `HTTPS (REST)`.

O diagrama não detalha as rotas da API nem o formato das mensagens.

### 2.2. Ambiente de Nuvem (Cloud Provider)

Ambiente identificado com a indicação `<<PRODUÇÃO>>`. Contém o Gateway de Rede e o Cluster de Aplicação.

#### 2.2.1. Gateway de Rede

Nó identificado com a indicação `<<Load Balancer>>`.

**Artefato identificado:**

- **Proxy Reverso (NGINX).**

**Comunicação representada:**

- Gateway de Rede → Phoenix Web Server, com o rótulo `Encaminhamento`.

#### 2.2.2. Cluster de Aplicação

Nó identificado com a indicação `<<Containers / Kubernets>>`. Contém uma área interna, sem nome, com dois artefatos.

**Artefatos identificados:**

- **Phoenix Web Server:** marcado com a indicação `<<Interface/API>>`.
- **NX/Bumblebee Workers:** marcado com a indicação `<DOMINIO/AI>>`.

**Comunicações representadas:**

- Phoenix Web Server ↔ NX/Bumblebee Workers, seta bidirecional com o rótulo `RCP NATIVO (COMUNICAÇÃO INTERNA)`.
- Phoenix Web Server → Redis, com o rótulo `TCP (LEITURA ULTRARRÁPIDA)`.
- NX/Bumblebee Workers → PostgreSQL, com o rótulo `GRAVA PARECER XAI (SQL)`.

O diagrama não especifica o número de instâncias de cada artefato nem a forma de escalonamento.

### 2.3. Cluster de Banco de Dados

Agrupamento identificado com a indicação `<<Persistência>>`. Está representado fora do ambiente de nuvem.

**Bancos identificados:**

- **Redis:** marcado com a indicação `<<FEATURE STORE/IN MEMORY>>`. Recebe a conexão do Phoenix Web Server.
- **PostgreSQL:** marcado com a indicação `<<COLD STORAGE / AUDITORIA>>`. Recebe a conexão dos NX/Bumblebee Workers.

A imagem não detalha os dados armazenados em cada banco nem a política de retenção.

## 3. Comunicações entre os nós

| Origem | Destino | Rótulo no diagrama | Direção |
|---|---|---|---|
| Aplicação WEB/MOBILE | Gateway de Rede (NGINX) | HTTPS (REST) | Unidirecional |
| Gateway de Rede (NGINX) | Phoenix Web Server | Encaminhamento | Unidirecional |
| Phoenix Web Server | NX/Bumblebee Workers | RCP NATIVO (COMUNICAÇÃO INTERNA) | Bidirecional |
| Phoenix Web Server | Redis | TCP (LEITURA ULTRARRÁPIDA) | Unidirecional |
| NX/Bumblebee Workers | PostgreSQL | GRAVA PARECER XAI (SQL) | Unidirecional |

Essas conexões documentam as direções representadas graficamente. A imagem, isoladamente, não permite determinar portas de rede, autenticação ou comportamento em caso de falha.

## 4. Resumo dos nós e artefatos

| Nó ou ambiente | Indicação no diagrama | Artefatos identificados |
|---|---|---|
| Dispositivo Cliente | `<<frontend>>` | Aplicação WEB/MOBILE |
| Ambiente de Nuvem (Cloud Provider) | `<<PRODUÇÃO>>` | Gateway de Rede; Cluster de Aplicação |
| Gateway de Rede | `<<Load Balancer>>` | Proxy Reverso (NGINX) |
| Cluster de Aplicação | `<<Containers / Kubernets>>` | Phoenix Web Server; NX/Bumblebee Workers |
| Cluster de Banco de Dados | `<<Persistência>>` | Redis; PostgreSQL |

## 5. Pontos a esclarecer

Os seguintes pontos podem exigir confirmação com a equipe ou consulta ao planejamento original:

1. **RCP nativo:** confirmar se o rótulo se refere a RPC (*Remote Procedure Call*) e qual mecanismo de comunicação será usado.
2. **Kubernets:** confirmar se a indicação se refere a Kubernetes e corrigir a grafia no diagrama.
3. **Localização dos bancos:** o Cluster de Banco de Dados está desenhado fora do Ambiente de Nuvem. Confirmar se ele faz parte do mesmo provedor.
4. **Acesso aos dados pelos workers:** apenas o Phoenix Web Server se conecta ao Redis. Esclarecer como os NX/Bumblebee Workers obtêm os dados do perfil.
5. **Camada de Aplicação:** o diagrama de componentes apresenta uma camada de Aplicação (Processar Solicitação, Avaliar Proposta Condicional), mas este diagrama indica apenas Interface/API e Domínio/AI. Confirmar em qual artefato a camada de Aplicação será executada.
6. **Analista:** o diagrama não representa o dispositivo ou a interface usada pelo Analista. Confirmar se ele usa a mesma Aplicação WEB/MOBILE.
7. **Monitor de Estabilidade (MLOps):** não há nó ou artefato correspondente neste diagrama.
8. **Leitura ultrarrápida:** esclarecer se a indicação representa uma meta de latência e qual é o valor esperado.
9. **Tecnologias:** confirmar se NGINX, Kubernetes, Phoenix, NX/Bumblebee, Redis e PostgreSQL são tecnologias aprovadas para o protótipo ou apenas indicações do diagrama.
10. **Escopo do protótipo:** definir quais nós serão reais, simulados ou ficarão fora do escopo do protótipo.

Esses pontos são questões em aberto, e não decisões confirmadas pelo diagrama.

## 6. Limites deste documento

Este documento registra os nós, os ambientes, os artefatos e as comunicações identificados na imagem.

Ele não define, por conta própria:

- tecnologias definitivas de implementação;
- provedor de nuvem;
- quantidade de instâncias ou estratégia de escalonamento;
- configurações de rede, segurança ou autenticação;
- estruturas de banco de dados;
- requisitos de desempenho não especificados.

Essas informações devem ser obtidas dos documentos de planejamento e das especificações aprovadas pela equipe.

## 7. Referência

**Fonte:** Diagrama de Implantação — Sistema Inteligente de Análise de Crédito, fornecido pela equipe do projeto.
