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
    uint8 private immutable _underlyingDecimals;

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
        console.log("balance of is ", balanceOf(owner));
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

    function deposit(uint256 assets, address owner) public virtual returns (uint256) {
        require(assets <= maxDeposit(owner), "ERC4626: deposit more than max");

        console.log("deposit assets are", assets);
        uint256 shares = previewDeposit(assets);
        console.log("deposit shares are", shares);
        _deposit(owner, assets, shares);

        return shares;
    }

    function mint(uint shares, address owner) public virtual returns (uint) {
        require(shares <= maxMint(owner));

        uint assets = previewMint(shares);

        _deposit(owner, assets, shares);

        return assets;
    }

    function withdraw(
        uint assets,
        address owner
    ) public virtual returns (uint) {
        require(assets <= maxWithdraw(owner));

        console.log("before shares");
        uint shares = previewWithdraw(assets);
        console.log("after shares", shares);

        _withdraw(owner, assets, shares);

        return assets;
    }

    function redeem(
        uint shares,
        address caller,
        address owner
    ) public virtual returns (uint) {
        require(shares <= maxRedeem(owner));

        uint assets = previewRedeem(shares);

        _withdraw(owner, assets, shares);

        return assets;
    }

    function _deposit(
        address owner,
        uint assets,
        uint shares
    ) internal virtual {
        _asset.transferFrom(owner, address(this), assets);

        _mint(owner, shares);

        _asset.approve(address(gauge), assets);
        gauge.deposit(assets, 0);

        emit Deposit(_msgSender(), owner, assets, shares);
    }

    function _withdraw(
        address owner,
        uint assets,
        uint shares
    ) internal virtual {
        console.log("before _burn and shares is ", shares);
        _burn(owner, shares);
        console.log("after _burn");
        gauge.withdrawToken(assets, 0);
        console.log("after withdrawToken gauge");

        _asset.transfer(owner, assets);
        console.log("after _asset transfer");

        emit Withdraw(_msgSender(), owner, owner, assets, shares);
    }

    function _convertToShares(
        uint assets,
        Math.Rounding rounding
    ) internal view virtual returns (uint) {
        console.log("convert assets are", assets);
        console.log("convert totalSupply are", totalSupply() + 10 ** _decimalOffset());
        console.log("convert totalAssets are", totalAssets() + 1);
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
