<br />
<div align="center">
  <a href="https://www.ledger.com/">
    <img src="https://cdn1.iconfinder.com/data/icons/minicons-4/64/ledger-512.png" width="100"/>
  </a>

<h1 align="center">ledger-ethereum</h1>

<p align="center">
    A Flutter plugin to scan, connect & sign transactions using Ledger Nano devices using USB & BLE
    <br />
    <a href="https://pub.dev/documentation/ledger_flutter/latest/"><strong>« Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/cake-tech/ledger-ethereum/issues">Report Bug</a>
    · <a href="https://github.com/cake-tech/ledger-ethereum/issues">Request Feature</a>
  </p>
</div>
<br/>

## Overview

Ledger Nano devices are the perfect hardware wallets for managing your crypto & NFTs on the go.
This Flutter package is a plugin for the [ledger_flutter](https://pub.dev/packages/ledger_flutter) package to get accounts and sign transactions using the 
Ethereum blockchain.

### Supported devices

|         | BLE                | USB                |
|---------|--------------------|--------------------|
| Android | :heavy_check_mark: | :heavy_check_mark: |
| iOS     | :heavy_check_mark: | :x:                |

### Installation

Install the latest version of this package via pub.dev:

```yaml
ledger_ethereum: ^latest-version
```

For integration with the Ledger Flutter package, check out the documentation [here](https://pub.dev/packages/ledger_flutter).

### Setup

Create a new instance of an `EthereumLedgerApp` and pass an instance of your `Ledger` object.

```dart
final app = EthereumLedgerApp(ledger);
```

## Usage

### Get public keys

Depending on the required blockchain and Ledger Application Plugin, the `getAccounts()` method can be used to fetch the 
public keys from the Ledger Nano device.

Based on the implementation and supported protocol, there might be only one public key in the list of accounts.

```dart
final accounts = await app.getAccounts(device);
```
