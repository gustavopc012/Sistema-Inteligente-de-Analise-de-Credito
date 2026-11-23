# Tarefas — Incremento 11: Cadastro e Histórico de Propostas

**Situação:** concluído em 23/11/2026 por Alan, com 34 testes novos (142 no total, 0 falhas). O armazenamento grava em arquivo DETS, conforme a alteração do RF11.14 na spec. A interface web ganhou o painel "Propostas salvas", que usa as novas rotas.

## Regras de execução

- Executar uma tarefa por vez.
- Conferir o resultado antes de avançar.
- Não alterar regras já aprovadas do MVP.
- Atualizar este documento conforme as tarefas forem concluídas.
- Não realizar commit ou push sem autorização.

## T11.1 — Inspecionar integração HTTP e JSON

- [x] Conferir a estrutura real do registro `:mod` do `:httpd` no Erlang/OTP 25.
- [x] Identificar como o corpo de uma requisição POST é disponibilizado pelo servidor.
- [x] Revisar o encoder `CreditEngine.Web.JSON` e os contratos atuais da API.
- [x] Definir os cuidados para decodificar JSON sem criar átomos dinamicamente.

**Critério de conclusão:** relatório técnico curto com os campos, funções e limitações confirmados no ambiente.

## T11.2 — Implementar ProposalStore

- [x] Criar `CreditEngine.ProposalStore` como GenServer.
- [x] Implementar cadastro e rejeição de identificadores duplicados.
- [x] Implementar consulta individual e listagem resumida.
- [x] Implementar consulta e atualização do histórico.
- [x] Garantir atualização conjunta do estado e do histórico.

**Critério de conclusão:** armazenamento implementado com contratos definidos e sem dependências externas.

## T11.3 — Testar ProposalStore

- [x] Testar inicialização e cadastro.
- [x] Testar rejeição de identificador duplicado.
- [x] Testar consulta e listagem.
- [x] Testar estado inicial e histórico vazio.
- [x] Testar registro de análise e atualização do estado.
- [x] Testar preservação de análises anteriores.
- [x] Testar isolamento entre propostas.

**Critério de conclusão:** todos os testes unitários do armazenamento passam.

## T11.4 — Integrar ProposalStore à supervisão OTP

- [x] Adicionar o processo à árvore de supervisão em `CreditEngine.Application`.
- [x] Preservar o `CircuitBreaker` existente.
- [x] Verificar inicialização e reinicialização supervisionada.

**Critério de conclusão:** aplicação inicia com os dois processos supervisionados e os testes existentes continuam passando.

## T11.5 — Implementar ProposalService

- [x] Criar `CreditEngine.ProposalService`.
- [x] Implementar cadastro utilizando `CreditEngine.Proposal.new/1`.
- [x] Implementar consulta, listagem e consulta do histórico.
- [x] Implementar análise de proposta cadastrada.
- [x] Registrar somente análises concluídas.
- [x] Tratar proposta inexistente e indisponibilidade do armazenamento.

**Critério de conclusão:** operações da camada de serviço funcionam sem duplicar regras do pipeline.

## T11.6 — Testar ProposalService

- [x] Testar cadastro válido e inválido.
- [x] Testar consulta, listagem e histórico.
- [x] Testar análise e reanálise.
- [x] Testar atualização de estado e preservação do histórico.
- [x] Testar ausência de registro em falhas sem decisão.
- [x] Testar proposta inexistente.

**Critério de conclusão:** testes unitários do serviço passam sem interferência entre execuções.

## T11.7 — Implementar decodificador JSON

- [x] Implementar decodificação de objetos e arrays.
- [x] Implementar strings, escapes e Unicode.
- [x] Implementar números, booleanos e `null`.
- [x] Rejeitar JSON malformado e conteúdo excedente.
- [x] Evitar criação dinâmica de átomos a partir de dados externos.
- [x] Manter compatibilidade com o encoder existente.

**Critério de conclusão:** decodificador implementado sem dependências externas.

## T11.8 — Testar decodificador JSON

- [x] Testar todos os tipos JSON suportados.
- [x] Testar estruturas aninhadas.
- [x] Testar escapes e Unicode.
- [x] Testar entradas malformadas e casos-limite.
- [x] Verificar que chaves externas não criam átomos dinamicamente.

**Critério de conclusão:** testes do decodificador passam.

## T11.9 — Ampliar CreditEngine.Web.API

- [x] Implementar cadastro.
- [x] Implementar consulta individual e listagem.
- [x] Implementar consulta de histórico.
- [x] Implementar análise de proposta cadastrada.
- [x] Mapear resultados para os códigos HTTP definidos.
- [x] Tratar erros sem expor detalhes internos.

**Critério de conclusão:** API integra todas as operações ao ProposalService.

## T11.10 — Ampliar CreditEngine.Web.Handler

- [x] Implementar as cinco rotas especificadas.
- [x] Tratar métodos e caminhos corretamente.
- [x] Ler corpos das requisições POST conforme a estrutura confirmada do `:httpd`.
- [x] Decodificar JSON e encaminhar os dados à API.
- [x] Preservar as rotas anteriores.

**Critério de conclusão:** novas rotas funcionam no servidor HTTP existente.

## T11.11 — Testar integração HTTP

- [x] Testar cadastro com sucesso e dados inválidos.
- [x] Testar identificador duplicado.
- [x] Testar consulta individual e listagem.
- [x] Testar histórico vazio e preenchido.
- [x] Testar análise e reanálise.
- [x] Testar proposta inexistente.
- [x] Testar JSON malformado.
- [x] Testar indisponibilidade do armazenamento.
- [x] Verificar os códigos HTTP e o formato das respostas.
- [x] Executar testes de regressão das rotas existentes.

**Critério de conclusão:** testes de integração HTTP passam.

## T11.12 — Validação geral do incremento

- [x] Executar todos os testes do projeto.
- [x] Executar `mix format --check-formatted`.
- [x] Executar `mix compile --warnings-as-errors`.
- [x] Corrigir eventuais regressões.
- [x] Confirmar que os requisitos funcionais foram atendidos.

**Critério de conclusão:** testes, formatação e compilação passam sem erros ou avisos.

## T11.13 — Atualizar documentação

- [x] Registrar o que foi efetivamente implementado.
- [x] Atualizar o README sem apagar o histórico de conclusão do MVP.
- [x] Registrar as limitações do armazenamento (DETS, em vez do armazenamento em memória previsto inicialmente).
- [x] Atualizar as decisões pendentes somente quando houver decisões efetivamente tomadas.
- [x] Registrar os resultados finais da verificação.

**Critério de conclusão:** documentação coerente com o código e os testes executados.
