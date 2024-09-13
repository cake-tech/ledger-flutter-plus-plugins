<br />
<div align="center">
  <a href="https://www.ledger.com/">
    <img src="https://bitcoin.org/img/icons/logotop.svg" width="600"/>
  </a>

<h1 align="center">ledger-bitcoin</h1>

<p align="center">
    A Flutter Ledger App Plugin for the Bitcoin blockchain
    <br />
    <a href="https://pub.dev/documentation/ledger_algorand/latest/"><strong>« Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/cake-tech/ledger_bitcoin/issues">Report Bug</a>
    · <a href="https://github.com/cake-tech/ledger_citcoin/issues">Request Feature</a>
    · <a href="https://pub.dev/packages/ledger_flutter">Ledger Flutter</a>
  </p>
</div>
<br/>

---

## Overview

Ledger Nano devices are the perfect hardware wallets for managing your crypto & NFTs on the go.
This Flutter package is a plugin for the [ledger_flutter](https://pub.dev/packages/ledger_flutter) package to get accounts and sign transactions using the Bitcoin blockchain.

## Getting started

### Installation

Install the latest version of this package via pub.dev:

```yaml
ledger_bitcoin: ^latest-version
```

For integration with the Ledger Flutter package, check out the documentation [here](https://pub.dev/packages/ledger_flutter).

### Setup

Create a new instance of an `BitcoinLedgerApp` and pass an instance of your `Ledger` object.

```dart
final app = BitcoinLedgerApp(ledger);
```

## Usage

### Get Wallet Address

Depending on the required blockchain and Ledger Application Plugin, the `getAccounts()` method can be used to fetch the main address from the Ledger Nano device.

```dart
final accounts = await app.getAccounts(device);
```

## License

The ledger_bitcoin SDK is released under the MIT License (MIT). See LICENSE for details.
