// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract IpfsStorage is Ownable  {

    uint256 private tax = 0;

    string[] private cids;

    function saveCID(string calldata cid) public {
        cids.push(cid);
    }

    function getCIDs() public view returns (string[] memory) {
        return cids;
    }

    function setTax(uint256 newTax) public onlyOwner {
        tax = newTax;
    }

    function getTax()  public view returns (uint256) {
        return tax;
    }
}
