// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./interfaces/IGauge.sol";
import "./interfaces/IRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./vault/YieldGranterVaultBase.sol";

contract YieldGranter is YieldGranterVaultBase, ReentrancyGuard {

    IRouter private router;

    IERC20 private token1;

    IERC20 private token2;

    IERC20 private lpToken;

    IERC20 private velo;

    uint256 private deadline;

    uint256 private donationsCount;

    mapping(address => uint256) private totalDonatedAmount;

    mapping(address => uint256) private userBalance;

    mapping(address => address) private donations;

    mapping(uint256 => address) private users;

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

    modifier claimAction() {
        _claimAll();
        _;
    }

    function getReserves() public view returns (uint256, uint256) {
        return router.getReserves(address(token1), address(token2), true);
    }

    function depositProxy(
        uint256 amountA,
        uint256 amountB,
        address toProject
    ) public nonReentrant claimAction {
        if (donations[msg.sender] == address(0)) {
            users[donationsCount] = msg.sender;
            donationsCount++;
        } else {
            require(userBalance[msg.sender] == 0,
                "You have an active donation. Please withdraw your current deposit to create new donation");
        }
        donations[msg.sender] = toProject;

        token1.approve(msg.sender, amountA * 2);
        token2.approve(msg.sender, amountB * 2);
        token1.transferFrom(msg.sender, address(this), amountA);
        token2.transferFrom(msg.sender, address(this), amountB);

        uint256 lpTokenAmount = _addLiquidity(amountA, amountB);
        super.deposit(address(this), lpTokenAmount);

        _mint(msg.sender, lpTokenAmount);
        userBalance[msg.sender] += lpTokenAmount;
    }

    function withdrawProxy(
        uint256 amount,
        uint256 amountAMin,
        uint256 amountBMin
    ) public nonReentrant claimAction {
        _withdrawProxy(amount, amountAMin, amountBMin);
    }

    function _withdrawProxy(
        uint256 amount,
        uint256 amountAMin,
        uint256 amountBMin
    ) private {
        approve(address(this), 1000000000000000000);
        require(allowance(msg.sender, address(this)) >= amount);
        require(userBalance[msg.sender] >= amount, "Insufficient balance");

        super.withdraw(msg.sender, amount);
        (uint256 amountA, uint256 amountB) = _removeLiquidity(amount, amountAMin, amountBMin);
        token1.transfer(msg.sender, amountA);
        token2.transfer(msg.sender, amountB);

        _burn(msg.sender, amount);
        userBalance[msg.sender] -= amount;
    }

    function claim() public nonReentrant {
        _claimAll();
    }

    function getDonatedAmount(address project) public view returns (uint256) {
        return totalDonatedAmount[project];
    }

    function _claim(address caller) private {
        address project = donations[caller];
        if (project == address(0)) return;
        //        require(project != address(0), "There is no project to donate, address 0");

        uint256 rewardAmount = getReward(velo);
        if (rewardAmount <= 0) return;
        //        require(rewardAmount > 0, "Reward is 0");
        uint256 userReward = rewardAmount * 9 / 10;
        uint256 projectReward = rewardAmount - userReward;

        velo.approve(address(this), rewardAmount * 2);
        velo.transferFrom(address(this), caller, userReward);
        velo.transferFrom(address(this), project, projectReward);
        totalDonatedAmount[project] += projectReward;
    }

    function _claimAll() private {
        for (uint256 i = 0; i < donationsCount; i++) {
            _claim(users[i]);
        }
    }

    function _addLiquidity(uint256 amountA, uint256 amountB) private returns (uint256) {
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

    function _removeLiquidity(
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
