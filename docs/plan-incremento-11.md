# Plano Técnico — Incremento 11: Cadastro e Histórico de Propostas

## 1. Objetivo

Definir a arquitetura e a sequência de implementação do Incremento 11, respeitando a especificação funcional aprovada em `docs/spec-incremento-11.md`.

O MVP concluído deverá ser preservado. As alterações serão incrementais e concentradas nos componentes necessários ao cadastro, armazenamento em memória, consulta e histórico das propostas.

## 2. Arquitetura proposta

A implementação será dividida em quatro responsabilidades principais:

1. **Modelo existente (`CreditEngine.Proposal`):** continuará representando e validando os dados da proposta. Não terá suas regras de validação modificadas.
2. **Armazenamento (`CreditEngine.ProposalStore`):** novo processo `GenServer`, responsável por manter propostas, estados atuais e históricos em memória.
3. **Serviço (`CreditEngine.ProposalService`):** nova camada responsável por orquestrar cadastro, consulta, listagem, histórico e análise de propostas cadastradas.
4. **API Web:** os módulos existentes serão ampliados para expor as novas operações HTTP.

## 3. Armazenamento — ProposalStore

Será criado `credit_engine/lib/credit_engine/proposal_store.ex`.

O módulo será um `GenServer` supervisionado pela aplicação OTP.

### 3.1 Estrutura dos registros

O estado interno manterá um mapa indexado pelo identificador textual da proposta.

Cada registro armazenará conceitualmente:

- `proposal`: struct `CreditEngine.Proposal`.
- `status`: estado atual, inicialmente `:nao_analisada`.
- `history`: lista de análises concluídas, inicialmente vazia.

### 3.2 Operações

O armazenamento deverá oferecer operações para:

- Cadastrar uma proposta.
- Buscar uma proposta por identificador.
- Listar identificadores e estados atuais.
- Consultar o histórico.
- Registrar uma análise concluída e atualizar o estado atual.

A rejeição de identificadores duplicados deverá ocorrer sem substituir o registro existente.

O histórico deverá preservar a ordem cronológica. Novas análises serão acrescentadas ao final.

### 3.3 Ciclo de vida

O processo será iniciado pela árvore de supervisão de `CreditEngine.Application`, utilizando a estratégia `:one_for_one`.

Os dados existirão somente enquanto o processo mantiver seu estado em memória. Não haverá persistência externa ou recuperação após reinicialização.

## 4. Serviço — ProposalService

Será criado `credit_engine/lib/credit_engine/proposal_service.ex`.

O serviço será a camada de aplicação que utilizará `ProposalStore` e `CreditEngine`.

Responsabilidades:

- Validar e cadastrar propostas por meio de `CreditEngine.Proposal.new/1`.
- Consultar propostas.
- Listar propostas sem expor seus dados complementares.
- Consultar históricos.
- Recuperar uma proposta cadastrada e executar `CreditEngine.analisar/1` com seus dados.
- Registrar no armazenamento somente análises concluídas com uma decisão válida.

O serviço não deverá duplicar regras de negócio do pipeline nem alterar o comportamento dos módulos existentes.

## 5. Registro das análises

Cada entrada do histórico conterá somente informações efetivamente disponíveis no resultado do pipeline:

- Identificador da proposta.
- Data e hora.
- Status.
- Score, quando disponível.
- Parecer (`explanation`), quando disponível.

O pipeline existente retorna `%CreditEngine.Decision{}` com `status`, `score` e `explanation`.

Etapas, distância e parâmetros adicionais são calculados separadamente pela API atual. Portanto, não serão incluídos no histórico como se fossem dados retornados pelo pipeline.

Uma falha de validação ou análise não deverá atualizar o estado atual nem acrescentar uma entrada ao histórico.

## 6. Integração com a aplicação OTP

O arquivo `credit_engine/lib/credit_engine/application.ex` será atualizado para incluir `CreditEngine.ProposalStore` na lista de processos supervisionados.

O `CircuitBreaker` existente deverá continuar supervisionado e funcionando conforme o comportamento atual.

## 7. Decodificação JSON

O projeto já possui `CreditEngine.Web.JSON`, responsável pela codificação de respostas.

O ambiente atual utiliza Erlang/OTP 25 e Elixir 1.14. Não será presumida a existência de um decodificador JSON nativo compatível.

Será implementado um decodificador próprio no projeto, sem dependências externas, contemplando:

- Objetos.
- Arrays.
- Strings e sequências de escape.
- Números.
- Booleanos.
- `null`.
- Rejeição de JSON malformado.

O decodificador deverá ter testes próprios, incluindo estruturas aninhadas e escapes Unicode.

O encoder existente será preservado. A integração deverá manter a representação JSON consistente com `CreditEngine.Web.JSON`.

## 8. API Web

Os módulos existentes `CreditEngine.Web.API` e `CreditEngine.Web.Handler` serão ampliados.

### 8.1 Rotas

| Método | Rota | Responsabilidade |
|---|---|---|
| POST | `/api/propostas` | Cadastrar proposta |
| GET | `/api/propostas/:id` | Consultar proposta |
| GET | `/api/propostas` | Listar propostas |
| GET | `/api/propostas/:id/historico` | Consultar histórico |
| POST | `/api/propostas/:id/analisar` | Analisar proposta cadastrada |

### 8.2 Tratamento HTTP

A API deverá mapear os resultados do serviço para os códigos definidos na especificação:

- `200`: consulta ou análise concluída.
- `201`: cadastro concluído.
- `404`: identificador inexistente.
- `409`: identificador duplicado.
- `422`: dados inválidos.
- `500`: indisponibilidade do armazenamento ou erro interno.

As mensagens de erro destinadas ao cliente serão genéricas e não revelarão detalhes internos.

### 8.3 Corpos das requisições

O cadastro receberá um objeto JSON com os campos aceitos por `CreditEngine.Proposal`.

A análise receberá o identificador pela rota e não deverá exigir novamente os dados do solicitante.

Antes de implementar a leitura do corpo HTTP, será conferida a estrutura real do registro `:mod` disponibilizado pelo `:httpd` da versão instalada. Não serão presumidos campos ou funções não confirmados no ambiente.

## 9. Tratamento de falhas e consistência

As chamadas ao armazenamento deverão tratar situações de indisponibilidade do processo.

Quando o armazenamento estiver indisponível:

- A operação não deverá ser apresentada como concluída.
- A API deverá retornar HTTP 500 com mensagem genérica.
- A falha deverá ser registrada em log quando aplicável.
- Não deverão ser retornados dados fictícios.
- Nenhuma atualização parcial de estado ou histórico deverá ser considerada bem-sucedida.

A atualização do estado e o acréscimo da entrada de histórico deverão ocorrer como uma única operação no `ProposalStore`.

## 10. Estratégia de testes

Serão adicionados testes unitários e de integração, mantendo a suíte existente.

### 10.1 ProposalStore

Testar:

- Inicialização.
- Cadastro.
- Rejeição de duplicidade.
- Consulta.
- Listagem.
- Estado inicial.
- Histórico vazio.
- Registro de análise.
- Atualização do estado.
- Preservação de análises anteriores.
- Isolamento entre propostas.

### 10.2 ProposalService

Testar:

- Cadastro válido e inválido.
- Consulta e listagem.
- Histórico.
- Análise de proposta cadastrada.
- Atualização de estado.
- Reanálise.
- Preservação do histórico.
- Ausência de registro em falhas sem decisão.
- Proposta inexistente.

### 10.3 Decodificador JSON

Testar:

- Objetos e arrays.
- Strings e escapes.
- Unicode.
- Números.
- Booleanos e `null`.
- Estruturas aninhadas.
- JSON malformado.

### 10.4 API Web

Testar:

- Todas as novas rotas.
- Cadastro e consulta.
- Listagem.
- Histórico vazio e preenchido.
- Análise e reanálise.
- Códigos HTTP.
- JSON inválido.
- Identificador inexistente e duplicado.
- Indisponibilidade do armazenamento.
- Regressão das rotas anteriores.

Os testes que compartilharem estado global ou processos supervisionados deverão ser organizados para evitar interferência entre execuções paralelas.

## 11. Sequência de implementação

A implementação seguirá esta ordem:

1. Criar `CreditEngine.ProposalStore` e seus contratos.
2. Criar os testes unitários do armazenamento.
3. Integrar o processo à supervisão OTP.
4. Criar `CreditEngine.ProposalService`.
5. Criar os testes unitários do serviço.
6. Implementar o decodificador JSON e seus testes.
7. Ampliar `CreditEngine.Web.API`.
8. Ampliar `CreditEngine.Web.Handler` com as novas rotas.
9. Criar testes de integração HTTP.
10. Executar a suíte completa, formatação e compilação.
11. Atualizar a documentação de conclusão do incremento.

Cada etapa deverá ser implementada e verificada antes de iniciar a seguinte.

## 12. Critérios técnicos de conclusão

O incremento estará tecnicamente concluído quando:

- Todos os requisitos de `docs/spec-incremento-11.md` estiverem implementados.
- Os testes novos e existentes passarem.
- `mix format --check-formatted` passar.
- `mix compile --warnings-as-errors` passar.
- A API existente continuar funcionando.
- A documentação refletir o comportamento efetivamente implementado.
- Nenhuma dependência externa nova tiver sido introduzida.
