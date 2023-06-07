// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
import "../interfaces/IGauge.sol";

abstract contract YieldGranterVaultBase is ERC20, IERC4626 {
    using Math for uint256;

    IGauge private gauge;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    constructor(
        address asset_,
        address _gauge
    ) ERC20("YieldGranter", "YGT") {

        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(IERC20(asset_));
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = IERC20(asset_);
        gauge = IGauge(_gauge);
    }

    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (success && encodedDecimals.length >= 32) {
            uint returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    function totalAssets() public view virtual returns (uint) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint assets) public view virtual returns (uint) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    function convertToAssets(uint shares) public view virtual returns (uint) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    function maxDeposit(address) public view virtual returns (uint) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    function maxRedeem(address owner) public view virtual returns (uint) {
        return balanceOf(owner);
    }

    function previewDeposit(uint assets) public view virtual returns (uint) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    function previewMint(uint shares) public view virtual returns (uint) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    function previewWithdraw(uint assets) public view virtual returns (uint) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    function previewRedeem(uint shares) public view virtual returns (uint) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    function deposit(uint256 assets, address caller) public virtual override returns (uint256) {
        require(assets <= maxDeposit(caller), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), caller, assets, shares);

        return shares;
    }

    function mint(uint shares, address receiver) public virtual returns (uint) {
        require(shares <= maxMint(receiver));

        uint assets = previewMint(shares);

        _deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function withdraw(
        uint assets,
        address receiver,
        address owner
    ) public virtual returns (uint) {
        require(assets <= maxWithdraw(owner));

        uint shares = previewWithdraw(assets);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function redeem(
        uint shares,
        address receiver,
        address owner
    ) public virtual returns (uint) {
        require(shares <= maxRedeem(owner));

        uint assets = previewRedeem(shares);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function _deposit(
        address caller,
        address receiver,
        uint assets,
        uint shares
    ) internal virtual {
        console.log("deposit 1");
        console.log("msgSender", msg.sender);
        console.log("_asset address", address(_asset));
        console.log("balance of", _asset.balanceOf(msg.sender));
        console.log("assets is ", assets);
        _asset.transferFrom(caller, address(this), assets);
        console.log("deposit 2");

        _mint(receiver, shares);
        console.log("deposit 3");

        _asset.approve(address(gauge), assets);
        console.log("deposit 4");
        gauge.deposit(assets, 0);
        console.log("deposit 5");
        console.log("balance caller after minting", balanceOf(caller));

        emit Deposit(caller, receiver, assets, shares);
        console.log("deposit 6");
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);

        _asset.transfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _convertToShares(
        uint assets,
        Math.Rounding rounding
    ) internal view virtual returns (uint) {
        return assets.mulDiv(
            totalSupply() + 10 ** _decimalOffset(),
            totalAssets() + 1,
            rounding
        );
    }

    function _convertToAssets(
        uint shares,
        Math.Rounding rounding
    ) internal view virtual returns (uint) {
        return shares.mulDiv(
            totalAssets() + 1,
            totalSupply() + 10 ** _decimalOffset(),
            rounding
        );
    }

    function _decimalOffset() internal view virtual returns (uint8) {
        return 0;
    }
}
