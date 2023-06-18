// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
import "../interfaces/IGauge.sol";

abstract contract YieldGranterVaultBase is ERC20 {
    using Math for uint256;

    IGauge private gauge;

    IERC20 private immutable _asset;

    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;

    // events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    constructor(
        address asset_,
        address _gauge
    ) ERC20("YieldGranter", "YGTT1") {
        _asset = IERC20(asset_);
        gauge = IGauge(_gauge);
    }

    function maxDeposit(address) public view virtual returns (uint) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint) {
        return balanceOf(owner);
    }

    function deposit(address caller, uint256 assets) internal virtual {
        require(assets <= maxDeposit(caller), "ERC4626: deposit more than max");

        _deposit(caller, assets);
    }

    function withdraw(address caller, uint256 assets) internal virtual {
        require(assets <= maxWithdraw(caller));
        _withdraw(caller, assets);
    }

    function getReward(IERC20 rewardToken) internal returns (uint256) {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(rewardToken);
        gauge.getReward(address(this), rewardTokens);
        return rewardToken.balanceOf(address(this));
    }

    function _deposit(
        address caller,
        uint assets
    ) internal virtual {
        _asset.approve(address(gauge), assets);
        gauge.depositAll(0);

        emit Deposit(_msgSender(), caller, assets, assets);
    }

    function _withdraw(
        address caller,
        uint256 assets
    ) internal virtual {
        gauge.withdrawToken(assets, 0);

        emit Withdraw(_msgSender(), caller, caller, assets, assets);
    }
}
