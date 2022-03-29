// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "ds-test/test.sol";
import "../Token.sol";

contract TokenTest is DSTest, ERC1155Holder {
    Token private token;
    address private taddr;
    address private me;
    Player private player;

    function setUp() public {
        token = new Token();
        taddr = address(token);
        me = token.creator();
        player = new Player();
    }

    function test_full() public {
        printBalance();
        
        token.safeTransferFrom(me, address(player), 2, 1, "0x0");

        printBalance();
    }

    function printBalance() public {
        emit log_string("----PRINTBALANCE----");
        emit log_named_uint("me", token.balanceOf(me, 2));
        emit log_named_uint("player", token.balanceOf(address(player), 2));
    }
}

contract Player is ERC1155Holder {
    
}