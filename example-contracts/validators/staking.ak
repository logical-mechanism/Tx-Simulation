use aiken/transaction.{Publish, ScriptContext, WithdrawFrom}
use assist/types.{ValidatorHash}

type StakeData {
  stake_cred: ValidatorHash,
}

type WithdrawRedeemer {
  Withdraw
  Delegate(StakeData)
}

// random_string is for initilizing different stake keys attached to the same starter token
validator {
  fn params(redeemer: WithdrawRedeemer, context: ScriptContext) -> Bool {
    // get reference utxo
    when context.purpose is {
      // handle all withdrawals
      WithdrawFrom(_) ->
        // if no reward is found error
        when redeemer is {
          // can only withdraw
          Withdraw -> True
          // all else fails
          _ -> False
        }
      // handle all delegation certs
      Publish(_) ->
        when redeemer is {
          // only delegate to secific pool
          Delegate(_) -> True
          // deregistration fails and anything else but changing delegation
          _ -> False
        }
      // anything else fails
      _ -> False
    }
  }
}
