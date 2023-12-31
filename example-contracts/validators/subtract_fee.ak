use aiken/transaction.{Input, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{Value}
use assist/addresses
use assist/count
use assist/find
use assist/payout
use assist/signing
use assist/types.{Wallet}

type Datum {
  owner: Wallet,
}

validator {
  fn params(this_datum: Datum, _redeemer: Void, context: ScriptContext) -> Bool {
    when context.purpose is {
      Spend(out_ref) -> {
        // tx being validated
        let tx: Transaction = context.transaction
        let this_input: Input = find.input_by_ref(tx.inputs, out_ref)
        let this_addr: Address = this_input.output.address
        let this_value: Value = this_input.output.value
        let new_value: Value = value.merge(this_value, value.negate(tx.fee))
        let owner_addr: Address = addresses.from_wallet(this_datum.owner)
        and {
          // single script input
          count.inputs_by_addr(tx.inputs, this_addr, 1),
          // single script output
          count.outputs_by_addr(tx.outputs, this_addr, 0),
          // owner must sign it
          signing.verify_sig(tx.extra_signatories, this_datum.owner.pkh),
          payout.exact(owner_addr, new_value, tx.outputs),
        }
      }

      // can only spend
      _ -> False
    }
  }
}
