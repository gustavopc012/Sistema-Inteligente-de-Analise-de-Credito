# Diagrama de Classes — Sistema Inteligente de Análise de Crédito

## 1. Visão geral

Este documento descreve os módulos, as estruturas de dados (*structs*), as funções, os atributos e os relacionamentos identificados no diagrama de classes do Sistema Inteligente de Análise de Crédito.

O objetivo é documentar os elementos representados graficamente, preservando as informações do diagrama original. As assinaturas e os nomes foram reproduzidos como aparecem na imagem, inclusive em casos de possível erro de digitação, que estão listados na seção 5.

O diagrama apresenta cinco elementos marcados como `<<Module>>` e dois marcados como `<<Struct>>`. Todos os relacionamentos aparecem como setas tracejadas.

## 2. Elementos do diagrama

### 2.1. Módulos

#### 2.1.1. CreditEngine.Safety.CircuitBreaker

Módulo marcado com a indicação `<<Module>>`.

**Função identificada:**

- `+avaliar_cenario_macro(proposta: Proposta Multimodal) : {:ok, Proposta} | {:error, :crise_sistemica}`

**Relacionamento representado:**

- CircuitBreaker → Proposta Multimodal, com o rótulo `valida`.

#### 2.1.2. CreditEngine.ML.Unsupervised

Módulo marcado com a indicação `<<Module>>`.

**Função identificada:**

- `+run_isolation_forest(proposta: PropostaMultimodal) : {:ok, Proposta} | {error, :fraude}`

**Relacionamento representado:**

- ML.Unsupervised → Proposta Multimodal, com o rótulo `filtra anomalias`.

#### 2.1.3. CreditEngine.ML.Supervised

Módulo marcado com a indicação `<<Module>>`.

**Função identificada:**

- `+predict_default_probability(proposta: PropostaMultimodal):Float`

**Relacionamento representado:**

- ML.Supervised → Proposta Multimodal, com o rótulo `calcula target Y = 1 | X`.

#### 2.1.4. Credit.Engine.Decision.Thresholds

Módulo marcado com a indicação `<<Module>>`.

**Funções identificadas:**

- `+otimizar_matriz_confusão()`
- `+classificar_decisao(score: Float) : : aprovado|:recusado|:analise_manual`

**Relacionamento representado:**

- Decision.Thresholds → CreditEngine.ML.Supervised, com o rótulo `Aplica regras de negócio`.

A imagem não especifica os parâmetros nem o retorno de `otimizar_matriz_confusão()`, nem os valores dos limiares usados em `classificar_decisao`.

#### 2.1.5. CreditEngine.Compilance.XAI

Módulo marcado com a indicação `<<Module>>`.

**Função identificada:**

- `+gera_explicabilidade_sharp(score: Float, proposta: PropostaMultimodal) : ParecerXAI`

**Relacionamento representado:**

- Compilance.XAI → ParecerXAI (seta tracejada, sem rótulo).

### 2.2. Structs

#### 2.2.1. Proposta Multimodal

Estrutura marcada com a indicação `<<Struct>>`. É o elemento que recebe o maior número de conexões no diagrama.

**Atributos identificados:**

- `+dados_cadastrais : Map`
- `+open finance : Map`
- `+biometria_comportamental : Map`
- `+biometria_comportamental : Map`
- `+dados_macroeconomicos : Map`

A imagem não detalha as chaves nem os valores esperados dentro de cada `Map`.

#### 2.2.2. ParecerXAI

Estrutura marcada com a indicação `<<Struct>>`.

**Elementos identificados:**

- `+predict_default_probability(proposta: PropostaMultimodal) :Float`
- `+status_decisao : Atom`
- `+shap_impacts : List<Map>`
- `+timestamp : DateTime`

O primeiro item está representado com a forma de uma função, e não de um atributo.

## 3. Relacionamentos entre os elementos

| Origem | Destino | Rótulo no diagrama |
|---|---|---|
| CreditEngine.Safety.CircuitBreaker | Proposta Multimodal | valida |
| CreditEngine.ML.Unsupervised | Proposta Multimodal | filtra anomalias |
| CreditEngine.ML.Supervised | Proposta Multimodal | calcula target Y = 1 \| X |
| Credit.Engine.Decision.Thresholds | CreditEngine.ML.Supervised | Aplica regras de negócio |
| CreditEngine.Compilance.XAI | ParecerXAI | (sem rótulo) |

Todas as setas são tracejadas, o que costuma indicar dependência. A imagem, isoladamente, não permite determinar a ordem em que as funções são chamadas nem qual componente faz essas chamadas.

## 4. Resumo dos elementos

| Elemento | Indicação | Funções ou atributos identificados |
|---|---|---|
| CreditEngine.Safety.CircuitBreaker | `<<Module>>` | avaliar_cenario_macro |
| CreditEngine.ML.Unsupervised | `<<Module>>` | run_isolation_forest |
| CreditEngine.ML.Supervised | `<<Module>>` | predict_default_probability |
| Credit.Engine.Decision.Thresholds | `<<Module>>` | otimizar_matriz_confusão; classificar_decisao |
| CreditEngine.Compilance.XAI | `<<Module>>` | gera_explicabilidade_sharp |
| Proposta Multimodal | `<<Struct>>` | dados_cadastrais; open finance; biometria_comportamental (2x); dados_macroeconomicos |
| ParecerXAI | `<<Struct>>` | predict_default_probability; status_decisao; shap_impacts; timestamp |

| Função | Retorno indicado no diagrama |
|---|---|
| avaliar_cenario_macro | `{:ok, Proposta} \| {:error, :crise_sistemica}` |
| run_isolation_forest | `{:ok, Proposta} \| {error, :fraude}` |
| predict_default_probability | `Float` |
| classificar_decisao | `aprovado \| :recusado \| :analise_manual` |
| gera_explicabilidade_sharp | `ParecerXAI` |
| otimizar_matriz_confusão | (não indicado) |

## 5. Pontos a esclarecer

Os seguintes pontos podem exigir confirmação com a equipe ou consulta ao planejamento original:

1. **Atributo duplicado:** `biometria_comportamental` aparece duas vezes em Proposta Multimodal. Confirmar se o segundo deveria ser outro atributo.
2. **Nome do atributo `open finance`:** o nome contém espaço. Confirmar a grafia pretendida.
3. **Nome do struct:** aparece como "Proposta Multimodal" (com espaço) no título e em CircuitBreaker, e como "PropostaMultimodal" nos demais parâmetros. Os retornos usam apenas "Proposta". Confirmar se todos se referem ao mesmo tipo.
4. **Namespace:** quatro módulos usam o prefixo `CreditEngine`, mas o de limiares usa `Credit.Engine`. Confirmar o padrão.
5. **Compilance:** confirmar se o nome pretendido é `Compliance`.
6. **SHARP x SHAP:** o módulo usa `gera_explicabilidade_sharp`, enquanto o struct ParecerXAI usa `shap_impacts`. Padronizar o nome.
7. **Retorno de `run_isolation_forest`:** aparece como `{error, :fraude}`, sem os dois-pontos antes de `error`, diferente de `{:error, :crise_sistemica}`. Confirmar se o formato é o mesmo.
8. **Retorno de `classificar_decisao`:** aparece como `: : aprovado|:recusado|:analise_manual`. Confirmar se os três valores são átomos.
9. **Função dentro de ParecerXAI:** `predict_default_probability` aparece como item de um struct e repete a função de ML.Supervised. Confirmar se o item pretendido era um atributo, como a probabilidade calculada.
10. **Relacionamento Thresholds → Supervised:** esclarecer o significado da seta "Aplica regras de negócio" e a relação entre `classificar_decisao` e o resultado de `predict_default_probability`.
11. **Rótulo `calcula target Y = 1 | X`:** confirmar se representa a probabilidade de inadimplência dado o perfil da proposta.
12. **Elementos ausentes:** o diagrama não representa as portas, a Feature Store, o Monitor de Estabilidade, nem os componentes de Interface e Aplicação que aparecem em outros diagramas. Confirmar se isso é intencional, com o diagrama cobrindo apenas o domínio.

Esses pontos são questões em aberto, e não decisões confirmadas pelo diagrama.

## 6. Limites deste documento

Este documento registra os módulos, os structs, as funções, os atributos e os relacionamentos identificados na imagem.

Ele não define, por conta própria:

- o conteúdo dos campos do tipo `Map`;
- valores de limiares ou critérios de classificação;
- algoritmos ou parâmetros dos modelos além dos nomes indicados;
- a ordem de chamada das funções;
- tecnologias definitivas de implementação;
- regras de aprovação ou reprovação de crédito.

Essas informações devem ser obtidas dos documentos de planejamento e das especificações aprovadas pela equipe.

## 7. Referência

**Fonte:** Diagrama de Classes — Sistema Inteligente de Análise de Crédito, fornecido pela equipe do projeto.
