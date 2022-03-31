# <h1 align="center"> NFT-Owned-Multi-Sig </h1>

**A multi-sig-wallet which supports member management with NFTs (ERC-1155)**

## Built upon

* https://github.com/gakonst/dapptools-template
* https://solidity-by-example.org/app/multi-sig-wallet/

## Building and testing

```sh
git clone https://github.com/0xfa1z/nft-owned-multi-sig
cd nft-owned-multi-sig
make # This installs the project's dependencies.
make test
```

## Installing the toolkit

If you do not have DappTools already installed, you'll need to run the below
commands

### Install Nix

```sh
# User must be in sudoers
curl -L https://nixos.org/nix/install | sh

# Run this or login again to use Nix
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

### Install DappTools

```sh
curl https://dapp.tools/install | sh
```

## DappTools Resources

* [DappTools](https://dapp.tools)
    * [Hevm Docs](https://github.com/dapphub/dapptools/blob/master/src/hevm/README.md)
    * [Dapp Docs](https://github.com/dapphub/dapptools/tree/master/src/dapp/README.md)
    * [Seth Docs](https://github.com/dapphub/dapptools/tree/master/src/seth/README.md)
* [DappTools Overview](https://www.youtube.com/watch?v=lPinWgaNceM)
* [Awesome-DappTools](https://github.com/rajivpo/awesome-dapptools)
