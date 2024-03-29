// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyPoints {
    mapping(address => uint256) public lpBalances;

    address owner;
    address public presaleMarketAddress; // Allow presaleMartet to be an authorised caller

    event LoyaltyPointsAdded(address indexed user, uint256 points);
    event LoyaltyPointsSubtracted(address indexed user, uint256 points);
    event LoyaltyPointsSet(address indexed user, uint256 points);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this.");
        _;
    }

    modifier onlyPresaleMarketOrOwner() {
        require(
            msg.sender == owner || msg.sender == presaleMarketAddress,
            "Unauthorized"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setPresaleMarketAddress(
        address _presaleMarketAddress
    ) external onlyOwner {
        presaleMarketAddress = _presaleMarketAddress;
    }

    function addLoyaltyPoints(address user, uint256 points) public onlyPresaleMarketOrOwner  {
        lpBalances[user] += points;
        emit LoyaltyPointsAdded(user, points);
    }

    function subtractLoyaltyPoints(
        address user,
        uint256 points
    ) public onlyOwner {
        require(lpBalances[user] >= points, "Insufficient balance.");
        lpBalances[user] -= points;
        emit LoyaltyPointsSubtracted(user, points);
    }

    // Other loyalty points management functions as needed

    //getter functions

    function setPoints(address user, uint256 points) public onlyOwner {
        lpBalances[user] = points;
        emit LoyaltyPointsSet(user, points);
    }
    function getPoints(address user) public view returns (uint256) {
        return lpBalances[user];
    }
}
