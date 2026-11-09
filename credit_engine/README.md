# CreditEngine — Sistema Inteligente de Análise de Crédito

Este repositório contém uma estrutura inicial executável para evoluções futuras. Nesta etapa, o projeto compila e possui testes automatizados, mas **não implementa decisões reais de crédito, cálculo de score ou detecção de fraude**.

## Requisitos

- Elixir 1.14 ou superior compatível com `~> 1.14`
- Erlang/OTP compatível com a versão instalada do Elixir

## Executar

Na raiz do projeto:

```bash
mix compile
mix test
```

Para abrir o console interativo:

```bash
iex -S mix
```

O projeto não possui dependências externas nesta etapa.

## Estrutura

```text
credit_engine/
├── lib/
│   ├── credit_engine.ex
│   └── credit_engine/
│       ├── application.ex
│       ├── proposal.ex
│       ├── decision.ex
│       ├── safety/circuit_breaker.ex
│       ├── ml/supervised.ex
│       ├── ml/unsupervised.ex
│       └── decision/thresholds.ex
├── test/
│   ├── test_helper.exs
│   └── credit_engine_test.exs
├── .formatter.exs
├── .gitignore
└── mix.exs
```

Os módulos de domínio são esqueletos. Não contêm algoritmos, limiares ou regras de negócio inventadas; funções ainda não especificadas retornam `{:error, :not_implemented}`.

## Próximos passos

1. Aprovar o escopo do MVP.
2. Criar `spec.md`, `plan.md` e `tasks.md` para o primeiro incremento.
3. Definir o contrato da proposta e as validações de entrada.
4. Implementar uma funcionalidade por vez, com testes e critérios de aceitação.
5. Adicionar dependências somente após decisão técnica da equipe.

## Diretrizes

- Utilizar dados sintéticos nos testes.
- Não inserir dados pessoais reais no repositório.
- Não versionar senhas, tokens ou chaves.
- Não definir scores, pesos ou limiares sem aprovação.
- Não declarar testes como aprovados sem executá-los.
