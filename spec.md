## Recebimento e validação de propostas

**Projeto:** Sistema Inteligente de Análise de Crédito  
**Equipe:** Omicron  
**Linguagem definida:** Elixir  
**Versão:** 0.1.0  
**Status:** Rascunho para revisão e aprovação

---

## 1. Objetivo

Implementar a funcionalidade inicial de recebimento e validação estrutural de propostas de crédito.

O sistema deverá receber os atributos de uma proposta, verificar se os dados obrigatórios e complementares respeitam os tipos esperados e retornar uma proposta estruturada ou um erro identificável.

Este incremento estabelece a base para os próximos componentes do sistema, sem implementar as etapas de análise de risco.

## 2. Escopo

### 2.1. Incluído

- Recebimento de atributos de uma proposta.
- Validação do formato dos atributos recebidos.
- Validação do identificador da proposta.
- Validação dos campos complementares.
- Rejeição de atributos desconhecidos.
- Retorno de resultados estruturados.
- Testes automatizados utilizando ExUnit.

### 2.2. Fora do escopo

Não fazem parte deste incremento:

- Cálculo de score de crédito.
- Aprovação ou reprovação de propostas.
- Classificação por thresholds.
- Detecção de fraude ou anomalias.
- Integração com fontes Open Finance.
- Integração com modelos de aprendizado de máquina.
- Geração de explicações SHAP.
- Análise humana de propostas.
- Persistência em banco de dados.
- Implementação do Circuit Breaker.
- Monitoramento Data Drift ou PSI.

Essas funcionalidades dependem de incrementos e definições próprios.

## 3. Estrutura de dados da proposta

A proposta deverá possuir os seguintes campos:

| Campo | Tipo esperado | Obrigatoriedade |
|---|---|---|
| id | String | Obrigatório |
| applicant_data | Map ou nil | Opcional |
| open_finance_data | Map ou nil | Opcional |
| behavioral_data | Map ou nil | Opcional |
| macroeconomic_data | Map ou nil | Opcional |

O campo `id` identifica a proposta.

Os campos complementares representam grupos de informações que poderão ser utilizados em etapas futuras do sistema.

Neste incremento, o conteúdo interno desses mapas não será submetido a validações de negócio.

## 4. Requisitos funcionais

### RF01 — Receber atributos da proposta

O sistema deverá disponibilizar uma operação para receber os atributos de uma proposta.

**Critérios de aceitação:**
- A operação deverá receber um mapa de atributos.
- Uma entrada que não seja um mapa deverá ser rejeitada.
- A operação deverá retornar um resultado estruturado.

### RF02 — Validar identificador

O sistema deverá exigir um identificador textual não vazio.

**Critérios de aceitação:**
- Uma proposta com identificador textual não vazio deverá passar por esta validação.
- Um identificador vazio deverá ser rejeitado.
- A ausência do identificador deverá ser rejeitada.
- Um identificador que não seja textual deverá ser rejeitado.

Não estão definidos neste incremento formatos específicos, tamanho máximo ou regras de unicidade para o identificador.

### RF03 — Validar campos complementares

Os campos `applicant_data`, `open_finance_data`, `behavioral_data` e `macroeconomic_data` deverão aceitar mapas ou valores `nil`.

**Critérios de aceitação:**
- Os quatro campos poderão estar ausentes.
- Os quatro campos poderão receber `nil`.
- Os quatro campos poderão receber mapas.
- Um campo complementar preenchido com outro tipo deverá ser rejeitado.
- A validação deverá identificar o campo inválido.

### RF04 — Rejeitar atributos desconhecidos

O sistema deverá rejeitar atributos que não estejam definidos na estrutura da proposta.

**Critérios de aceitação:**
- Atributos não reconhecidos deverão gerar um erro estruturado.
- O resultado deverá identificar os campos desconhecidos.
- A proposta não deverá ser criada quando existirem atributos desconhecidos.

### RF05 — Retornar resultado estruturado

A operação de criação deverá retornar:

- `{:ok, proposal}` quando a proposta for válida.
- `{:error, reason}` quando a entrada for inválida.

Os motivos de erro deverão permitir identificar a categoria da falha.

## 5. Requisitos não funcionais

### RNF01 — Implementação

A funcionalidade deverá ser implementada em Elixir, utilizando a estrutura de projeto Mix.

### RNF02 — Testabilidade

As regras de validação deverão possuir testes automatizados com ExUnit.

### RNF03 — Segurança dos dados

Os testes e exemplos deverão utilizar dados sintéticos, sem informações pessoais reais de clientes.

### RNF04 — Manutenibilidade

A validação deverá permanecer organizada em módulos e funções com responsabilidades claras.

## 6. Critérios gerais de conclusão

O incremento será considerado concluído quando:

1. A operação de recebimento de propostas estiver implementada.
2. Todos os critérios de aceitação dos requisitos funcionais forem verificados.
3. Os testes automatizados relacionados forem executados.
4. Não existirem falhas nos testes pertinentes.
5. Os resultados reais da compilação e dos testes forem registrados.
6. A implementação estiver coerente com esta especificação.
7. As limitações e pendências estiverem documentadas.

## 7. Rastreabilidade

| Origem | Relação com o incremento |
|---|---|
| README.md | Objetivo de organizar e processar dados das propostas |
| AGENTS.md | Regras de implementação, testes e segurança |
| Diagrama de casos de uso | Caso de uso Solicitar Análise de Crédito |
| Diagrama de classes | Estrutura de proposta representada na arquitetura |
| Fluxo SDD | Processo de especificação, revisão, planejamento e implementação |

A estrutura de dados deste incremento é uma etapa preparatória. Ela não representa a implementação completa do caso de uso Solicitar Análise de Crédito.

## 8. Pendências e limitações

Os seguintes pontos não são definidos por esta especificação:

- Formato definitivo e regra de unicidade do identificador.
- Validação interna dos dados de cada mapa complementar.
- Estrutura definitiva dos dados recebidos de Open Finance.
- Regras de negócio relacionadas à análise de crédito.
- Persistência e ciclo de vida das propostas.

Essas definições deverão ser tratadas em incrementos posteriores, quando necessárias.

## 9. Aprovação

**Status atual:** aguardando revisão.

| Responsável | Situação |
|---|---|
| Equipe Omicron | Aprovação pendente |
| Especificação | Rascunho elaborado |

Nenhuma funcionalidade fora deste escopo está autorizada por este documento.
