// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WhitelistMock {
    bool public wasCalled = false;

    function isWhitelisted(address) external returns (bool) {
        wasCalled = true;
        return true;
    }
}
