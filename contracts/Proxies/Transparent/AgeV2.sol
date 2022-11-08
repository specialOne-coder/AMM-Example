// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AgeV2 {
    uint256 private age;
    uint256 ageV2;

    // Emitted when the stored value changes
    event AgeChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        age = newValue;
        emit AgeChanged(newValue);
    }

    // Reads the last stored value
    function getAge() public view returns (uint256) {
        return age;
    }

    function getAgeV2() public view returns (uint256) {
        return ageV2 + 1;
    }


}