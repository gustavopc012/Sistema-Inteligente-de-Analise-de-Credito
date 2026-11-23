# O cadastro de propostas (incremento 11) grava em arquivo. Nos testes, o
# arquivo é separado (config/config.exs) e começa vazio a cada execução.
:ok = CreditEngine.ProposalStore.limpar()

# Fecha o arquivo ao final, para não deixá-lo marcado como "não fechado".
ExUnit.after_suite(fn _resultado ->
  Logger.configure(level: :error)
  Application.stop(:credit_engine)
end)

ExUnit.start()
