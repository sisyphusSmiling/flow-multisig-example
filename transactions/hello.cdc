/// Simple dry run transaction to demonstrate sending a multisig transaction
///
transaction {
    prepare(signer: &Account) {
        panic("Hello from ".concat(signer.address.toString()))
    }
}