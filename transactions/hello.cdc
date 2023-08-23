/// Simple dry run transaction to demonstrate sending a multisig transaction
///
transaction {
    prepare(signer: AuthAccount) {
        panic("Hello from ".concat(signer.address.toString()))
    }
}