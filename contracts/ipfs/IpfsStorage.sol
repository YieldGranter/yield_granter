// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract IpfsStorage {

    string[] public cids;

    function saveCID(string memory cid) public {
        cids.push(cid);
    }
}
