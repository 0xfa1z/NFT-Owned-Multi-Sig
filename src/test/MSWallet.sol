// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../MSWallet.sol";

contract MSWalletTest is DSTest {
    MSUser private user;
    MSUser private recipient;
    MSWallet private multiSig;
    address private punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address private member = 0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1;

    function setUp() public {
        multiSig = new MSWallet(punks, 2);
        user = new MSUser(multiSig);
        recipient = new MSUser(multiSig);

        payable(address(multiSig)).transfer(15);
        
        emit log_named_address("NFT", punks);
        emit log_named_address("User1", address(user));
        emit log_named_address("MSWallet", address(multiSig));
        emit log_named_address("Recipient", address(recipient));
        emit log_named_uint("InitialBalance", address(multiSig).balance);
    }

    function test_full() public {
        MSUser user2 = new MSUser(multiSig);
        multiSig.propose(address(recipient), 2, "", member);
        multiSig.propose(address(recipient), 5, "", member);
        user.sign(0, member);
        user2.sign(0, member);
        user.execute(0, member);

        getTotalSupply();
        emit log_named_uint("MSWalletBalance", address(multiSig).balance);
        emit log_named_uint("RecipientBalance", address(recipient).balance);
        emit log_named_uint("TransactionCount", multiSig.getTransactionCount());
    }

    function testFail_full() public {
        multiSig.propose(address(recipient), 2, "", member);
        multiSig.propose(address(recipient), 5, "", member);
        user.sign(0, member);
        user.execute(0, member);

        getTotalSupply();
        emit log_named_uint("MSWalletBalance", address(multiSig).balance);
        emit log_named_uint("RecipientBalance", address(recipient).balance);
        emit log_named_uint("TransactionCount", multiSig.getTransactionCount());
    }

    function getTotalSupply() public {
        uint x;
        (bool success, bytes memory data) = punks.call{gas: 1000000}(
            abi.encodeWithSignature("totalSupply()")
        );
        require (success == true, "could not check total supply");
        assembly {
            x := mload(add(data, 0x20))
        }
        emit log_named_uint("TotalSupply", x);
    }
}

contract MSUser {
    MSWallet private multiSig;

    constructor(MSWallet wallet) {
        multiSig = wallet;
    }

    receive() external payable {}

    function sign(uint _txIndex, address _from) public {
        multiSig.sign(_txIndex, _from);
    }

    function execute(uint _txIndex, address _from) public {
        multiSig.execute(_txIndex, _from);
    }
}