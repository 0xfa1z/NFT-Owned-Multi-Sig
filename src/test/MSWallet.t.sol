// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "ds-test/test.sol";
import "../MSWallet.sol";
import "../Token.sol";

contract MSWalletTest is DSTest {
    Token private token;
    address private creator;

    MSUser private user1;
    MSUser private user2;
    MSUser private user3;
    MSUser private recipient;
    MSWallet private multiSig;

    function setUp() public {
        token = new Token(3);
        multiSig = new MSWallet(address(token), 0, 2);
        user1 = new MSUser(multiSig);
        user2 = new MSUser(multiSig);
        user3 = new MSUser(multiSig);
        recipient = new MSUser(multiSig);
        
        creator = token.creator();

        payable(address(multiSig)).transfer(15);
    }

    function test_full() public {
        printBalance();

        user1.mint(token);
        user2.mint(token);
        user3.mint(token);

        printBalance();

        emit log_named_uint("balance", token.balanceOf(address(user1), 0));

        user1.proposeTx(address(recipient), 2, "");
        user1.sign(0);
        user2.sign(0);
        user1.execute(0);
    }

    function printBalance() public {
        emit log_string("----PRINTBALANCE----");
        emit log_named_uint("creator", token.balanceOf(creator, 0));
        emit log_named_uint("member1", token.balanceOf(address(user1), 0));
        emit log_named_uint("member2", token.balanceOf(address(user2), 0));
        emit log_named_uint("member3", token.balanceOf(address(user3), 0));
    }
}

contract MSUser is ERC1155Holder {
    MSWallet private multiSig;

    constructor(MSWallet wallet) {
        multiSig = wallet;
    }
    
    receive() external payable {}

    function mint(Token token) public {
        token.mint();
    }

    function proposeTx(address _to, uint _value, bytes memory _data) public {
        multiSig.proposeTx(_to, _value, _data);
    }

    function sign(uint _txIndex) public {
        multiSig.sign(_txIndex);
    }

    function execute(uint _txIndex) public {
        multiSig.execute(_txIndex);
    }
}