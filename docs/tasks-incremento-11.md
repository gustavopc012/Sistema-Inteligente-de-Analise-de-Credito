# Tarefas — Incremento 11: Cadastro e Histórico de Propostas

## Regras de execução

- Executar uma tarefa por vez.
- Conferir o resultado antes de avançar.
- Não alterar regras já aprovadas do MVP.
- Atualizar este documento conforme as tarefas forem concluídas.
- Não realizar commit ou push sem autorização.

## T11.1 — Inspecionar integração HTTP e JSON

- [ ] Conferir a estrutura real do registro `:mod` do `:httpd` no Erlang/OTP 25.
- [ ] Identificar como o corpo de uma requisição POST é disponibilizado pelo servidor.
- [ ] Revisar o encoder `CreditEngine.Web.JSON` e os contratos atuais da API.
- [ ] Definir os cuidados para decodificar JSON sem criar átomos dinamicamente.

**Critério de conclusão:** relatório técnico curto com os campos, funções e limitações confirmados no ambiente.

## T11.2 — Implementar ProposalStore

- [ ] Criar `CreditEngine.ProposalStore` como GenServer.
- [ ] Implementar cadastro e rejeição de identificadores duplicados.
- [ ] Implementar consulta individual e listagem resumida.
- [ ] Implementar consulta e atualização do histórico.
- [ ] Garantir atualização conjunta do estado e do histórico.

**Critério de conclusão:** armazenamento implementado com contratos definidos e sem dependências externas.

## T11.3 — Testar ProposalStore

- [ ] Testar inicialização e cadastro.
- [ ] Testar rejeição de identificador duplicado.
- [ ] Testar consulta e listagem.
- [ ] Testar estado inicial e histórico vazio.
- [ ] Testar registro de análise e atualização do estado.
- [ ] Testar preservação de análises anteriores.
- [ ] Testar isolamento entre propostas.

**Critério de conclusão:** todos os testes unitários do armazenamento passam.

## T11.4 — Integrar ProposalStore à supervisão OTP

- [ ] Adicionar o processo à árvore de supervisão em `CreditEngine.Application`.
- [ ] Preservar o `CircuitBreaker` existente.
- [ ] Verificar inicialização e reinicialização supervisionada.

**Critério de conclusão:** aplicação inicia com os dois processos supervisionados e os testes existentes continuam passando.

## T11.5 — Implementar ProposalService

- [ ] Criar `CreditEngine.ProposalService`.
- [ ] Implementar cadastro utilizando `CreditEngine.Proposal.new/1`.
- [ ] Implementar consulta, listagem e consulta do histórico.
- [ ] Implementar análise de proposta cadastrada.
- [ ] Registrar somente análises concluídas.
- [ ] Tratar proposta inexistente e indisponibilidade do armazenamento.

**Critério de conclusão:** operações da camada de serviço funcionam sem duplicar regras do pipeline.

## T11.6 — Testar ProposalService

- [ ] Testar cadastro válido e inválido.
- [ ] Testar consulta, listagem e histórico.
- [ ] Testar análise e reanálise.
- [ ] Testar atualização de estado e preservação do histórico.
- [ ] Testar ausência de registro em falhas sem decisão.
- [ ] Testar proposta inexistente.

**Critério de conclusão:** testes unitários do serviço passam sem interferência entre execuções.

## T11.7 — Implementar decodificador JSON

- [ ] Implementar decodificação de objetos e arrays.
- [ ] Implementar strings, escapes e Unicode.
- [ ] Implementar números, booleanos e `null`.
- [ ] Rejeitar JSON malformado e conteúdo excedente.
- [ ] Evitar criação dinâmica de átomos a partir de dados externos.
- [ ] Manter compatibilidade com o encoder existente.

**Critério de conclusão:** decodificador implementado sem dependências externas.

## T11.8 — Testar decodificador JSON

- [ ] Testar todos os tipos JSON suportados.
- [ ] Testar estruturas aninhadas.
- [ ] Testar escapes e Unicode.
- [ ] Testar entradas malformadas e casos-limite.
- [ ] Verificar que chaves externas não criam átomos dinamicamente.

**Critério de conclusão:** testes do decodificador passam.

## T11.9 — Ampliar CreditEngine.Web.API

- [ ] Implementar cadastro.
- [ ] Implementar consulta individual e listagem.
- [ ] Implementar consulta de histórico.
- [ ] Implementar análise de proposta cadastrada.
- [ ] Mapear resultados para os códigos HTTP definidos.
- [ ] Tratar erros sem expor detalhes internos.

**Critério de conclusão:** API integra todas as operações ao ProposalService.

## T11.10 — Ampliar CreditEngine.Web.Handler

- [ ] Implementar as cinco rotas especificadas.
- [ ] Tratar métodos e caminhos corretamente.
- [ ] Ler corpos das requisições POST conforme a estrutura confirmada do `:httpd`.
- [ ] Decodificar JSON e encaminhar os dados à API.
- [ ] Preservar as rotas anteriores.

**Critério de conclusão:** novas rotas funcionam no servidor HTTP existente.

## T11.11 — Testar integração HTTP

- [ ] Testar cadastro com sucesso e dados inválidos.
- [ ] Testar identificador duplicado.
- [ ] Testar consulta individual e listagem.
- [ ] Testar histórico vazio e preenchido.
- [ ] Testar análise e reanálise.
- [ ] Testar proposta inexistente.
- [ ] Testar JSON malformado.
- [ ] Testar indisponibilidade do armazenamento.
- [ ] Verificar os códigos HTTP e o formato das respostas.
- [ ] Executar testes de regressão das rotas existentes.

**Critério de conclusão:** testes de integração HTTP passam.

## T11.12 — Validação geral do incremento

- [ ] Executar todos os testes do projeto.
- [ ] Executar `mix format --check-formatted`.
- [ ] Executar `mix compile --warnings-as-errors`.
- [ ] Corrigir eventuais regressões.
- [ ] Confirmar que os requisitos funcionais foram atendidos.

**Critério de conclusão:** testes, formatação e compilação passam sem erros ou avisos.

## T11.13 — Atualizar documentação

- [ ] Registrar o que foi efetivamente implementado.
- [ ] Atualizar o README sem apagar o histórico de conclusão do MVP.
- [ ] Registrar limitações do armazenamento em memória.
- [ ] Atualizar as decisões pendentes somente quando houver decisões efetivamente tomadas.
- [ ] Registrar os resultados finais da verificação.

**Critério de conclusão:** documentação coerente com o código e os testes executados.
