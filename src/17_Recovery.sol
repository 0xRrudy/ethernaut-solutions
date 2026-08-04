// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    // Generate a token without storing its deployed address.
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // Collect Ether in return for tokens.
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // Allow transfers of tokens.
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // Send the contract's Ether balance to the selected recipient.
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
