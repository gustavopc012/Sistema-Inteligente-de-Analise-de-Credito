# Especificação — Incremento 11: Cadastro e Histórico de Propostas

## 1. Objetivo

Implementar o cadastro, a consulta, a listagem e o acompanhamento do histórico de análises de propostas de crédito.

O incremento permitirá que uma proposta seja cadastrada uma única vez, consultada posteriormente e submetida a novas análises sem perder os resultados anteriores.

A implementação deverá reutilizar o modelo `CreditEngine.Proposal` e o pipeline de análise já existente, preservando o MVP concluído.

## 2. Escopo funcional

O incremento contempla:

- Cadastro de propostas.
- Consulta individual de propostas.
- Listagem de propostas cadastradas.
- Consulta do histórico de análises.
- Análise de propostas previamente cadastradas.
- Atualização do estado atual da proposta após uma análise válida.
- Registro de cada análise concluída no histórico.

Não fazem parte deste incremento:

- Persistência em banco de dados.
- Recuperação de dados após reinicialização.
- Implementação de decisões humanas para propostas encaminhadas à análise manual.
- Alterações nas regras de validação já existentes em `CreditEngine.Proposal`.
- Redesenho da interface visual existente.

## 3. Identificação e cadastro

### RF11.1 — Identificador da proposta

O identificador será informado pelo emissor da proposta.

A comparação será textual e exata. Não haverá conversão de maiúsculas/minúsculas ou normalização do identificador.

Identificadores duplicados serão rejeitados. Um cadastro duplicado não poderá sobrescrever uma proposta existente.

### RF11.2 — Dados da proposta

O cadastro reutilizará a estrutura atual de `CreditEngine.Proposal`, com os seguintes campos:

- `id`
- `applicant_data`
- `open_finance_data`
- `behavioral_data`
- `macroeconomic_data`

Os campos complementares continuarão aceitando mapas ou `nil`, conforme a validação já implementada.

A validação existente não deverá ser alterada neste incremento.

### RF11.3 — Estado inicial

Toda proposta cadastrada começará com o estado `:nao_analisada`.

## 4. Estados e histórico

### RF11.4 — Estado atual

Após uma análise concluída, o estado atual da proposta representará o resultado da análise mais recente.

Os estados possíveis após análise são:

- `:aprovado`
- `:analise_manual`
- `:recusado`
- `:recusa_automatica`
- `:recusa_seguranca`

O estado `:analise_manual` representa apenas o encaminhamento para análise humana. A decisão humana não será implementada neste incremento.

### RF11.5 — Registro do histórico

Cada análise concluída deverá gerar uma nova entrada no histórico, sem apagar ou substituir entradas anteriores.

Cada entrada conterá:

- Identificador da proposta.
- Data e hora da análise.
- Status retornado pelo pipeline.
- Score, quando disponível.
- Parecer, quando disponível.

Somente informações efetivamente retornadas pelo pipeline serão registradas. Etapas, distância e parâmetros calculados separadamente pela API não serão tratados como dados produzidos pelo pipeline nem incluídos neste histórico.

### RF11.6 — Reanálise

Uma proposta poderá ser analisada mais de uma vez.

Cada reanálise concluída deverá gerar uma nova entrada no histórico. O estado atual da proposta deverá refletir o resultado mais recente.

### RF11.7 — Falhas sem decisão

Tentativas que não produzirem uma decisão válida, como entradas inválidas ou erros de análise, não deverão gerar entradas no histórico nem alterar o estado atual da proposta.

## 5. Operações da aplicação

### RF11.8 — Cadastrar proposta

Permitir o cadastro de uma proposta com os campos definidos nesta especificação.

### RF11.9 — Consultar proposta

Permitir a consulta de uma proposta pelo identificador.

A consulta individual deverá retornar:

- Identificador.
- Estado atual.
- `applicant_data`.
- `open_finance_data`.
- `behavioral_data`.
- `macroeconomic_data`.

O histórico será consultado por uma operação separada.

### RF11.10 — Listar propostas

Retornar as propostas cadastradas contendo somente:

- Identificador.
- Estado atual.

A listagem não deverá expor dados pessoais ou dados complementares das propostas.

### RF11.11 — Consultar histórico

Retornar as entradas do histórico da proposta em ordem cronológica, da mais antiga para a mais recente.

Se a proposta existir e ainda não tiver sido analisada, a operação deverá retornar uma lista vazia.

Se a proposta não existir, deverá retornar erro de não encontrado.

### RF11.12 — Analisar proposta cadastrada

A análise deverá receber o identificador pela rota, recuperar os dados cadastrados e executar o pipeline existente com esses dados.

A operação não deverá receber novamente os dados do solicitante no corpo da requisição.

Após uma análise concluída, deverá atualizar o estado atual e acrescentar a entrada correspondente ao histórico.

## 6. API HTTP

Serão adicionadas as seguintes rotas à API web existente:

| Método | Rota | Operação |
|---|---|---|
| POST | `/api/propostas` | Cadastrar proposta |
| GET | `/api/propostas/:id` | Consultar proposta |
| GET | `/api/propostas` | Listar propostas |
| GET | `/api/propostas/:id/historico` | Consultar histórico |
| POST | `/api/propostas/:id/analisar` | Analisar proposta cadastrada |

### RF11.13 — Códigos HTTP

As respostas deverão utilizar os seguintes códigos:

| Código | Significado |
|---|---|
| 200 | Consulta ou análise concluída |
| 201 | Proposta cadastrada |
| 404 | Proposta inexistente |
| 409 | Identificador duplicado |
| 422 | Dados inválidos |
| 500 | Erro interno ou indisponibilidade do armazenamento |

As respostas deverão utilizar JSON compatível com o encoder `CreditEngine.Web.JSON` existente.

Erros internos não deverão expor detalhes de implementação ao cliente.

## 7. Armazenamento

### RF11.14 — Armazenamento em memória

As propostas e seus históricos serão mantidos em memória por meio de um processo `GenServer`, supervisionado pela aplicação OTP.

O armazenamento será volátil: os dados serão perdidos quando a aplicação for reiniciada.

Não haverá banco de dados nem recuperação automática neste incremento.

### RF11.15 — Indisponibilidade do armazenamento

Se o armazenamento estiver indisponível, a aplicação não deverá retornar dados fictícios nem indicar que uma operação foi concluída.

A API deverá retornar erro HTTP 500 com mensagem genérica. Quando aplicável, a falha deverá ser registrada em log.

Uma operação não concluída não poderá alterar o estado ou o histórico da proposta.

## 8. Restrições técnicas

- Linguagem: Elixir.
- Compatibilidade com a versão Elixir e Erlang/OTP já utilizadas pelo projeto.
- Reutilização da aplicação OTP e da API web existentes.
- Armazenamento em memória por `GenServer`.
- Nenhuma dependência externa nova.
- O decodificador JSON necessário para receber corpos HTTP deverá ser implementado no próprio projeto, contemplando objetos, arrays, strings, números, booleanos e `null`.
- O encoder JSON existente deverá ser preservado.
- O pipeline de análise e as regras de negócio existentes deverão ser preservados.

## 9. Critérios de aceitação

O incremento será considerado concluído quando:

1. Uma proposta válida puder ser cadastrada.
2. Um identificador duplicado for rejeitado sem sobrescrever o cadastro existente.
3. Uma proposta cadastrada puder ser consultada individualmente.
4. A listagem retornar somente identificador e estado atual.
5. O histórico puder ser consultado em ordem cronológica.
6. Uma proposta sem análises retornar histórico vazio.
7. Uma proposta cadastrada puder ser analisada sem reenviar os dados do solicitante.
8. Cada análise concluída gerar uma nova entrada no histórico.
9. Reanálises preservarem todas as entradas anteriores.
10. Falhas que não produzam decisão não alterarem estado nem histórico.
11. As rotas HTTP retornarem os códigos definidos nesta especificação.
12. A indisponibilidade do armazenamento for tratada sem simular sucesso.
13. Os testes existentes do MVP continuarem passando.
14. Compilação, formatação e testes do projeto forem executados com sucesso.
