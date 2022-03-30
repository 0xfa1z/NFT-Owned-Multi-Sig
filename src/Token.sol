// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Token is ERC1155 {
    address public creator;
    uint8 public maxGovTokens;
    uint8 public numMinted = 0;
    bool public allMinted = false;
    uint256 public constant GOV = 0;

    constructor(uint8 _maxGovTokens) ERC1155("") {
        creator = msg.sender;
        maxGovTokens = _maxGovTokens;
    }

    function mint() public {
        if(!allMinted && numMinted < 3) {
            _mint(msg.sender, GOV, 1, "");
            numMinted++;
        }
    }
}