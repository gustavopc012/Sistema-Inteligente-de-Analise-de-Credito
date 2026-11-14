# Verificação — Incremento 1: Recebimento e validação de propostas

## 1. Objetivo

Este documento registra a verificação da implementação de `CreditEngine.Proposal` contra os critérios de aceitação do `spec.md` (versão 0.1.0), conforme a Etapa 5 do `docs/fluxo-sdd.md`.

A verificação não presume que o código está correto: cada critério foi conferido por um teste automatizado executado, e os resultados abaixo são os resultados reais obtidos.

## 2. Ambiente e comandos

- **Data:** 12/11/2026.
- **Ponto de partida:** commit `34e26fe` do branch `main`.
- **Ambiente:** Elixir 1.14.0 e Erlang/OTP 25, em Linux.

Comandos executados na pasta `credit_engine/`:

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix test
```

O ambiente usado não é o computador de nenhum integrante. Recomenda-se repetir `mix test` em pelo menos uma máquina da equipe.

## 3. Resultados da execução

| Momento | Resultado |
|---|---|
| Estado inicial (`34e26fe`) | 13 testes, 0 falhas |
| Após adicionar os testes de critérios sem cobertura | 16 testes, 0 falhas |
| Após adicionar o teste de RF04 com chaves em texto, antes da correção | 17 testes, 1 falha: retorno `{:error, :invalid_fields}` |
| Após a correção | 17 testes, 0 falhas; compilação sem avisos; formatação conferida |

## 4. Requisitos funcionais

| Requisito | Critério de aceitação | Evidência (teste) | Resultado |
|---|---|---|---|
| RF01 | Receber um mapa de atributos | cria uma proposta com identificador válido | Passou |
| RF01 | Rejeitar entrada que não seja mapa | rejeita atributos que não sejam mapas | Passou |
| RF01 | Retornar resultado estruturado | Todos os testes de `new/1` conferem a tupla de retorno | Passou |
| RF02 | Aceitar identificador textual não vazio | cria uma proposta com identificador válido | Passou |
| RF02 | Rejeitar identificador vazio | rejeita identificador vazio | Passou |
| RF02 | Rejeitar ausência do identificador | rejeita proposta sem identificador | Passou |
| RF02 | Rejeitar identificador não textual | rejeita identificador não textual (novo) | Passou |
| RF03 | Campos complementares ausentes | cria uma proposta com identificador válido | Passou |
| RF03 | Campos complementares com `nil` | aceita nil nos campos complementares (novo) | Passou |
| RF03 | Campos complementares com mapas | aceita mapas nos campos complementares | Passou |
| RF03 | Rejeitar outro tipo e identificar o campo | rejeita campos complementares que não sejam mapas | Passou |
| RF04 | Erro estruturado que identifica os campos desconhecidos (chaves átomo) | rejeita campos desconhecidos | Passou |
| RF04 | Erro estruturado que identifica os campos desconhecidos (chaves em texto) | identifica campos desconhecidos com chaves em texto (novo) | Falhou antes da correção; passou depois |
| RF04 | Não criar a proposta com campos desconhecidos | Os dois testes acima conferem que o retorno é `{:error, _}` | Passou |
| RF05 | Retornar `{:ok, proposal}` ou `{:error, reason}` | Todos os testes de `new/1` | Passou |
| RF05 | Motivo de erro que identifique a categoria | Retornos `:invalid_id`, `:invalid_attributes`, `{:invalid_field, campo}` e `{:unknown_fields, campos}` | Passou |

Os testes marcados como "(novo)" foram adicionados nesta verificação.

## 5. Requisitos não funcionais

| Requisito | Evidência | Resultado |
|---|---|---|
| RNF01 — Elixir com projeto Mix | `credit_engine/mix.exs` | Atendido |
| RNF02 — Testes com ExUnit | 17 testes em `credit_engine/test/` | Atendido |
| RNF03 — Dados sintéticos | Identificadores `PROP-00X` e valores fictícios | Atendido |
| RNF04 — Manutenibilidade | Validação concentrada em `CreditEngine.Proposal`, com funções privadas por responsabilidade | Atendido (avaliação qualitativa) |

## 6. Critérios gerais de conclusão (seção 6 do `spec.md`)

| Critério | Situação |
|---|---|
| 1. Operação de recebimento implementada | Atendido |
| 2. Critérios de aceitação verificados | Atendido (seções 4 e 5) |
| 3. Testes automatizados executados | Atendido |
| 4. Nenhuma falha nos testes pertinentes | Atendido após a correção |
| 5. Resultados reais registrados | Atendido (este documento) |
| 6. Implementação coerente com a especificação | Atendido após a correção do RF04 |
| 7. Limitações e pendências documentadas | Atendido (seção 8) |

O incremento só deve ser considerado encerrado após a aprovação do `spec.md` pela equipe (ver seção 8).

## 7. Correção realizada

**Problema:** quando os atributos chegavam com chaves em texto (por exemplo, `"campo_x"`), um campo desconhecido fazia `String.to_existing_atom/1` lançar `ArgumentError`. A função capturava o erro e retornava `{:error, :invalid_fields}`, sem identificar o campo, o que contraria o RF04.

**Correção:** as chaves em texto passaram a ser comparadas com os nomes dos campos conhecidos, sem criar átomos novos. Chaves desconhecidas permanecem como texto e aparecem em `{:error, {:unknown_fields, [...]}}`. O retorno `{:error, :invalid_fields}`, que não constava do `spec.md`, deixou de existir.

A correção preserva os requisitos e a arquitetura aprovados, sendo tratada como correção interna conforme a seção "Controle de mudanças" do `docs/fluxo-sdd.md`.

## 8. Pendências e limitações

1. **Aprovação do `spec.md`:** a especificação ainda está com o status "aguardando revisão".
2. **Ambiente de execução:** os testes foram executados fora das máquinas da equipe. Recomenda-se repetir localmente.
3. **Chave repetida em átomo e em texto:** se a entrada trouxer o mesmo campo nas duas formas (por exemplo, `:id` e `"id"`), apenas um dos valores é mantido. O `spec.md` não define esse caso.
4. **Fora do escopo deste incremento:** o `mix.exs` não registra `CreditEngine.Application` (`mod: {CreditEngine.Application, []}`). Isso será necessário quando houver processos supervisionados, como um Circuit Breaker implementado com GenServer. *Resolvido em 13/11/2026: a aplicação passou a ser registrada no `mix.exs`.*
5. **Ferramentas:** o Credo, previsto no quadro da equipe, ainda não foi configurado.

## 9. Referências

- `spec.md` — Recebimento e validação de propostas, versão 0.1.0.
- `docs/fluxo-sdd.md` — Etapa 5, verificação independente.
- `credit_engine/lib/credit_engine/proposal.ex` e `credit_engine/test/credit_engine/proposal_test.exs`.
