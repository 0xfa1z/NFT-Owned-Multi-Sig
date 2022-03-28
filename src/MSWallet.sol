// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MSWallet {
    event Deposit(address sender, uint amount, uint balance);
    event TxProposal(
        address member,
        uint txIndex,
        address to,
        uint value,
        bytes data
    );
    event Sign(address member, uint txIndex);
    event Unsign(address member, uint txIndex);
    event Execute(address member, uint txIndex);

    address public collection;
    uint8 public numSigsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numSignitures;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isSigned;

    Transaction[] public transactions;

    modifier onlyMember(address addr) {
        uint x;
        (bool success, bytes memory data) = collection.call{gas: 1000000}(
            abi.encodeWithSignature("balanceOf(address)", addr)
        ); 
        require (success == true, "could not verify member");
        assembly {
            x := mload(add(data, 0x20))
        }
        require(x > 0, "is not member");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notSigned(address member, uint256 _txIndex) {
        require (isSigned[_txIndex][member] == false, 
            "tx has already been signed");
        _;
    }

    modifier txReady(uint256 _txIndex) {
        Transaction memory t = transactions[_txIndex];
        require (t.numSignitures >= numSigsRequired, "tx not confirmed.");
        require (!t.executed, "tx already executed.");
        _;
    }

    constructor (address _collection, uint8 _numSigsRequired) {
        require (_numSigsRequired > 0, "invalid number of required signitures");

        uint x;
        (bool success, bytes memory data) = collection.call{gas: 1000000}(
            abi.encodeWithSignature("totalSupply()")
        );
        require (success == true, "could not check total supply");
        assembly {
            x := mload(add(data, 0x20))
        }
        require(_numSigsRequired < x, "invalid number of required signitures");

        numSigsRequired = _numSigsRequired;
        collection = _collection;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function propose(address _to, uint _value, bytes memory _data, address _from) public 
        onlyMember(_from) 
    {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numSignitures: 0
            })
        );

        emit TxProposal(_from, transactions.length-1, _to, _value, _data);
    }

    function sign(uint256 _txIndex, address _from) public 
        onlyMember(_from) 
        txExists(_txIndex) 
        notSigned(msg.sender, _txIndex) 
    {
        transactions[_txIndex].numSignitures++;
        isSigned[_txIndex][msg.sender] = true;

        emit Sign(_from, _txIndex);
    }

    function unsign(uint256 _txIndex, address _from) public 
        onlyMember(_from) 
        txExists(_txIndex) 
    {
        require(isSigned[_txIndex][msg.sender], "Transaction not signed");

        transactions[_txIndex].numSignitures -= 1;
        isSigned[_txIndex][msg.sender] = false;

        emit Unsign(_from, _txIndex);
    }

    function execute(uint256 _txIndex, address _from) public 
        onlyMember(_from) 
        txExists(_txIndex) 
        txReady(_txIndex) 
    {
        Transaction storage t = transactions[_txIndex];
        t.executed = true;

        (bool success, ) = t.to.call{value: t.value, gas: 1000000}(
            t.data
        );
        require(success, "tx failed");

        emit Execute(_from, _txIndex);
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numSignitures
        );
    }
}
