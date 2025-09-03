// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Succession {
    uint256 public lastVisited;
    uint256 public immutable tenYears;
    address public owner;
    address payable public recipient;

    event Deposited(address indexed from, uint256 amount);
    event Claimed(address indexed by, uint256 amount);
    event RecipientChanged(
        address indexed oldRecipient,
        address indexed newRecipient
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    event Pinged(address indexed owner);

    constructor(address payable _recipient) payable {
        require(_recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "Initial funding required");

        tenYears = 365 days * 10;
        lastVisited = block.timestamp;
        owner = msg.sender;
        recipient = _recipient;

        emit Deposited(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient, "Not recipient");
        _;
    }

    function deposit() external payable onlyOwner {
        require(msg.value > 0, "No ether sent");
        lastVisited = block.timestamp;
        emit Deposited(msg.sender, msg.value);
    }

    function ping() external onlyOwner {
        lastVisited = block.timestamp;
        emit Pinged(owner);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function changeRecipient(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        emit RecipientChanged(recipient, _recipient);
        recipient = _recipient;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function claim() external onlyRecipient {
        require(
            block.timestamp >= lastVisited + tenYears,
            "Too early to claim"
        );
        uint256 bal = address(this).balance;
        require(bal > 0, "No balance");
        emit Claimed(recipient, bal);
        (bool success, ) = recipient.call{value: bal}("");
        require(success, "Transfer failed");
    }
}