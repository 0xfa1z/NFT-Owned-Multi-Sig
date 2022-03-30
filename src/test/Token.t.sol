// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "ds-test/test.sol";
import "../Token.sol";

contract TokenTest is DSTest, ERC1155Holder {
    Token private token;
    address private taddr;
    address private creator;
    Member private member1;
    Member private member2;
    Member private member3;

    function setUp() public {
        token = new Token(3);
        taddr = address(token);
        creator = token.creator();
        member1 = new Member();
        member2 = new Member();
        member3 = new Member();
    }

    function test_full() public {
        printBalance();
        
        //token.safeTransferFrom(me, address(member1), 0, 1, "0x0");
        member1.mint(token);
        member2.mint(token);
        member3.mint(token);
        member2.mint(token);

        printBalance();
    }

    function printBalance() public {
        emit log_string("----PRINTBALANCE----");
        emit log_named_uint("creator", token.balanceOf(creator, 0));
        emit log_named_uint("member1", token.balanceOf(address(member1), 0));
        emit log_named_uint("member2", token.balanceOf(address(member2), 0));
        emit log_named_uint("member3", token.balanceOf(address(member3), 0));
    }
}

contract Member is ERC1155Holder {
    function mint(Token token) public {
        token.mint();
    }
}