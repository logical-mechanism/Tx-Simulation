use aiken/transaction.{ScriptContext, Spend}

validator {
  fn params(_datum: Void, _redeemer: Void, context: ScriptContext) -> Bool {
    when context.purpose is {
      Spend(_) -> True
      // spending only
      _ -> False
    }
  }
}
