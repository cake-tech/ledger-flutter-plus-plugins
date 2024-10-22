<br />
<div align="center">
  <a href="https://www.ledger.com/">
    <img src="https://cdn1.iconfinder.com/data/icons/minicons-4/64/ledger-512.png" alt="Ledger Logo" width="100"/>
  </a>

<h1 align="center">ledger-ethereum</h1>

<p align="center">
    A Flutter plugin to scan, connect & sign transactions using Ledger Nano devices using USB & BLE
    <br />
    <a href="https://github.com/cake-tech/ledger-flutter-plus-plugins/issues">Report Bug · Request Feature</a>
  </p>
</div>
<br/>

## Overview

Ledger devices are the perfect hardware wallets for managing your crypto & NFTs on the go.
This Flutter package is a plugin for the [ledger_flutter_plus](https://pub.dev/packages/ledger_flutter_plus) package to get accounts and sign transactions using the 
Ethereum blockchain.

### Installation

Install the latest version of this package via pub.dev:

```yaml
ledger_ethereum: ^latest-version
```

For integration with the Ledger Flutter package, check out the documentation [here](https://pub.dev/packages/ledger_flutter_plus).

### Setup

Create a new instance of an `EthereumLedgerApp` and pass an instance of your `LedgerConnection` object.

```dart
final app = EthereumLedgerApp(connection);
```

## Usage

### Get public keys

Depending on the required blockchain and Ledger Application Plugin, the `getAccounts()` method can be used to fetch the 
public keys from the Ledger device.

Based on the implementation and supported protocol, there might be only one public key in the list of accounts.

```dart
final accounts = await app.getAccounts();
```
