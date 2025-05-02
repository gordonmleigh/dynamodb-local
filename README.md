# DynamoDB Local

This script sets up a local instance of DynamoDB on MacOS. It will be installed to "$HOME/dynamodb-local".

There you will also find the data file(s), and a copy of the install script that you can use to update the installation, or uninstall it.

## Usage

### Install

> [!CAUTION]
> You really should inspect the content of the script before pasting the following line into your terminal.

```shell
curl -sL https://raw.githubusercontent.com/gordonmleigh/dynamodb-local/refs/heads/main/install.sh | bash
```

### Update

```shell
~/dynamodb-local/install.sh
```

### Uninstall

```shell
~/dynamodb-local/install.sh uninstall
```
