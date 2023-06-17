// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./vault/YieldGranterVaultBase.sol";

contract YieldGranter is YieldGranterVaultBase, ReentrancyGuard {

    IRouter private router;

    IERC20 private token1;

    IERC20 private token2;

    IERC20 private lpToken;

    IERC20 private velo;

    uint256 private deadline;

    mapping (address => uint256) public donatedAmount;

    constructor(
        address _gauge,
        address _router,
        address _token1,
        address _token2,
        address _lpToken,
        address _velo
    ) YieldGranterVaultBase(_lpToken, _gauge){
        router = IRouter(_router);
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        lpToken = IERC20(_lpToken);
        velo = IERC20(_velo);
    }

    function depositProxy(uint256 amountA, uint256 amountB) external {
        token1.transferFrom(msg.sender, address(this), amountA);
        token2.transferFrom(msg.sender, address(this), amountB);
        uint256 lpTokenAmount = addLiquidity(amountA, amountB);
        uint256 shares = super.deposit(lpTokenAmount, address(this));
    }

    function withdrawProxy(uint256 amount, uint256 amountAMin, uint256 amountBMin) external {
        uint lpTokenAmount = super.withdraw(amount, address(this));
        removeLiquidity(lpTokenAmount, amountAMin, amountBMin);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) private returns (uint256) {
        token1.approve(address(router), amountA * 2);
        token2.approve(address(router), amountB * 2);
        _updateDeadline();
        router.addLiquidity(
            address(token1),
            address(token2),
            true,
            uint256(amountA),
            uint256(amountB),
            uint256(amountA * 98 / 100),
            uint256(amountB * 98 / 100),
            address(this),
            _getDeadline()
        );
        return lpToken.balanceOf(address(this));
    }

    function removeLiquidity(
        uint256 lpTokenAmount,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        lpToken.approve(address(router), 1000000000000000000);
        _updateDeadline();
        (amountA, amountB) = router.removeLiquidity(
            address(token1),
            address(token2),
            true,
            lpTokenAmount,
            amountAMin,
            amountBMin,
            address(this),
            _getDeadline()
        );
    }

    function _getDeadline() private view returns (uint256) {
        return deadline;
    }

    function _updateDeadline() private {
        deadline = block.timestamp + 10 minutes;
    }
}
