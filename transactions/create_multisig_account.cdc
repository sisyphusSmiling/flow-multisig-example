/// Constructs a new account, funding creation with the signing account and adds the given keys to the new account at
/// the specified weights.
///
transaction(publicKeys: [String], weights: [UFix64]) {

    prepare(signer: auth(BorrowValue) &Account) {

        assert(publicKeys.length == weights.length, message: "Mismatched number of keys and weights")
        
        let newAccount = Account(payer: signer)

        // Iterate over given keys, adding each to the new account at their corresponding weights
        for i, key in publicKeys {
            let pubKey = PublicKey(
                    publicKey: key.decodeHex(),
                    signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
                )

            newAccount.keys.add(
                publicKey: pubKey,
                hashAlgorithm: HashAlgorithm.SHA2_256,
                weight: weights[i]
            )
        }
    }
}