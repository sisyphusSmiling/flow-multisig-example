# Flow CLI Multisig Example

This repo contains a simple walkthrough for creating a multisig account and signing multisig transactions using Flow CLI

:information_source: If you haven't already, [install Flow CLI](https://developers.flow.com/tooling/flow-cli/install) to follow along on your machine.

## Single Account, Multiple Signers

### Multisig Account Creation

Run the emulator

```sh
flow emulator
```

Generate the keys we'll use for our multisig parties by running the following:

```sh
flow keys generate
```

This will generate a public/private key pair like so:

> :warning: Don't use the keys below in production!

```sh
🔴️ Store private key safely and don't share with anyone!
Private Key             eea425158b8e2689149e520322997d077a267f5b2523f555c724c8f32164a8c1
Public Key              b25315335721fc33dc64bb24f4260944f774d481085bbac1757674026f71afae6a8ba0a16847def3e3cf09e6a86606a8327268df448b916271c9e80003ac3f1d
Mnemonic                fly globe profit finger this pencil know memory spin wet game behave
Derivation Path         m/44'/539'/0'/0/0
Signature Algorithm     ECDSA_P256
```

We'll run the command again to get another key pair:

```sh
🔴️ Store private key safely and don't share with anyone!
Private Key             5f6d92e9ff29cade6a04555e5abe26e3503dded0f64e7ba2a32d177776761464
Public Key              43e0c86cce645b40f95dc5fd3f967d1f23b15c209080f5ff8878fc5b3c1e8a2f9378d0574822532f4de39357cd15d632a714c2570cd2d95f918241c66c65396f
Mnemonic                win wrestle cash dune segment series knee field work reduce correct shoe
Derivation Path         m/44'/539'/0'/0/0
Signature Algorithm     ECDSA_P256
```

With these two keys, let's create a new account and assign these keys at `500.0` weight each - this will get us a 2/2 multisig account, with both key signatures adding up to the requisite `1000.0` weight needed for transaction authorization.

> :information_source: This transaction will be signed by the emulator's default `emulator-account`. Since Flow's account model demands an existing account to create and fund a new one, this signing account will fund the creation of the new account. In the [transaction we run](./transactions/create_multisig_account.cdc), we'll subsequently add the given public keys to the newly created account at the weights specified in the provided transaction arguments.

```sh
flow transactions send ./transactions/create_multisig_account.cdc \
    '["b25315335721fc33dc64bb24f4260944f774d481085bbac1757674026f71afae6a8ba0a16847def3e3cf09e6a86606a8327268df448b916271c9e80003ac3f1d","43e0c86cce645b40f95dc5fd3f967d1f23b15c209080f5ff8878fc5b3c1e8a2f9378d0574822532f4de39357cd15d632a714c2570cd2d95f918241c66c65396f"]' \
    '[500.0, 500.0]'
```

You'll see a number of events emitted, including `flow.AccountCreated` which will give us the address of the newly created account. We can query for the event with:

```sh
flow events get flow.AccountCreated
```

And the event at the most recent block will give us the account address - `0xe03daebed8ca0615`

Now, we can validate the keys we added in the previous transaction by running:

```sh
flow accounts get 0xe03daebed8ca0615
```

Which gives us:

```sh
Address	 0xe03daebed8ca0615
Balance	 0.00100000
Keys	 2

Key 0   Public Key              b25315335721fc33dc64bb24f4260944f774d481085bbac1757674026f71afae6a8ba0a16847def3e3cf09e6a86606a8327268df448b916271c9e80003ac3f1d
        Weight                  500
        Signature Algorithm     ECDSA_P256
        Hash Algorithm          SHA2_256
        Revoked                 false
        Sequence Number         0
        Index                   0


Key 1   Public Key		        43e0c86cce645b40f95dc5fd3f967d1f23b15c209080f5ff8878fc5b3c1e8a2f9378d0574822532f4de39357cd15d632a714c2570cd2d95f918241c66c65396f
        Weight                  500
        Signature Algorithm     ECDSA_P256
        Hash Algorithm          SHA2_256
        Revoked                 false
        Sequence Number         0
        Index                   1

Contracts Deployed: 0
```

### Updating `flow.json`

With the account created and keys added, we'll now want to update our config in the `flow.json`. We need to make sure that the new account is listed under the `accounts` field and that the key indices are listed for each named signer.

Your `accounts` field should look as follows:

```json
"accounts": {
    "emulator-account": {
        "address": "f8d6e0586b0a20c7",
        "key": "94bf73ce1b12958e6091200ac21e43ddee67140c6312492ceb6fb115f4ea0984"
    },
    "alice": {
        "address": "0xe03daebed8ca0615",
        "key": {
            "type": "hex",
            "index": 0,
            "signatureAlgorithm": "ECDSA_P256",
            "hashAlgorithm": "SHA2_256",
            "privateKey": "eea425158b8e2689149e520322997d077a267f5b2523f555c724c8f32164a8c1"
        }
    },
    "bob": {
        "address": "0xe03daebed8ca0615",
        "key": {
            "type": "hex",
            "index": 1,
            "signatureAlgorithm": "ECDSA_P256",
            "hashAlgorithm": "SHA2_256",
            "privateKey": "5f6d92e9ff29cade6a04555e5abe26e3503dded0f64e7ba2a32d177776761464"
        }
    }
}
```

Notice that the address is listed as the same for both `alice` and `bob`, but the keys and indices differ. This will allow us to refer to the named signers when building and signing transactions with the cli.

### Building & Sending Multisig Transaction

With our account created and keys added, we can now send a transaction. For simplicity, we're going to run a simple dry run transaction that panics with the signer's address. This will be enough to demonstrate that the multisig functions.

This process will consist of three primary steps:

1. Build
1. Sign
1. Send

#### 1. Build

First, we'll need to [build the transaction](https://developers.flow.com/tooling/flow-cli/transactions/build-transactions#docusaurus_skipToContent_fallback). In this we'll name a proposer, payer, and authorizer as well as how to handle the built transaction blob.

> :information_source: Note that every flow transaction requires a dedicated proposal key. The key's sequence number is incremented every time it's used as a proposal key to prevent transaction replay attacks. This is why we must list the proposal key's index number explicitly. More about proposal keys [here](https://developers.flow.com/concepts/start-here/accounts-and-keys#proposal-key)

```sh
flow transactions build ./transactions/hello.cdc --proposer alice --proposer-key-index 0 --payer alice --authorizer alice --filter payload --save hello.rlp
```

The above command builds the transaction and saves the transaction payload blob to `hello.rlp`, using alice's key as the proposal key. Notice that we list one authorizer since we'll only be working with a single account. Multisig follows in the next step.

#### 2. Sign

Next, we'll sign the transaction blob with both signers.

```sh
flow transactions sign hello.rlp --signer alice --signer bob --filter payload --save hello.rlp
```

#### 3. Send

Lastly, we send the signed transaction

```sh
flow transactions send-signed hello.rlp
```

#### Confirmation

To confirm multisig was successful, we should see the following result - an expected panic emitting the signer's address:

```sh
ID	ae23e68e6861fba25826aad43ef98c84c47460b176929fcb466902da4caed484
Payer	e03daebed8ca0615
Authorizers	[e03daebed8ca0615]

Proposal Key:
    Address	e03daebed8ca0615
    Index	0
    Sequence	0

No Payload Signatures


Block ID	6df91347445c528f8d305d3b77e504f2a332a8b6752aa501e1c5f95f5e53ce25
Block Height	5
❌ Transaction Error
[Error Code: 1101] error caused by: 1 error occurred:
	* transaction execute failed: [Error Code: 1101] cadence runtime error: Execution failed:
error: panic: Hello from 0xe03daebed8ca0615
 --> ae23e68e6861fba25826aad43ef98c84c47460b176929fcb466902da4caed484:5:8
  |
5 |         panic("Hello from ".concat(signer.address.toString()))
  |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Conclusion

In this demo, we

- Created a new account
- Added two `500.0/1000.0` weight keys onto the account
- Built, signed, and sent a 2/2 multisig transaction

Even though this demo is simple, it contains all the building blocks you need for more complex configurations. You could add an arbitrary number of keys on an account at arbitrary weights. Want a 5/8 multisig? Add 8 keys at `200.0` weight onto an account.

Since Flow's account model has native support for multisig, adding, revoking, and rotating keys is extremely simple. The hope is that this demo introduced you well enought to the nuance involved in the configuration and tooling so you can use the feature set as best fits your use case.