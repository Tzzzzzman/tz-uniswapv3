// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {Tick} from "./lib/Tick.sol";
import {Position} from "./lib/Position.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapV3MintCallback} from "./interfaces/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title 池子合约，Uniswap的核心合约
 */
contract UniswapV3Pool {
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // 代币对地址
    address public immutable token0;
    address public immutable token1;

    // 当前价格和tick存储在一起以优化gas消耗
    struct Slot0 {
        // 当前sqrt(P)
        uint160 sqrtPriceX96;
        // 当前tick
        int24 tick;
    }

    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    // 流动性数量：L
    uint128 public liquidity;

    // Ticks信息
    mapping(int24 => Tick.Info) public ticks;
    // 头寸信息
    mapping(bytes32 => Position.Info) public positions;

    constructor(address _token0, address _token1, uint160 sqrtPriceX96, int24 tick) {
        token0 = _token0;
        token1 = _token1;
        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }

    /**
     * 提供流动性（铸币）
     *
     * @param owner 流动性提供者
     * @param lowerTick 上限刻度
     * @param upperTick 下限刻度
     * @param amount 提供流动性的数量
     * @return amount0 代币0的数量
     * @return amount1 代币1的数量
     */
    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        if (lowerTick >= upperTick || lowerTick < MIN_TICK || upperTick > MAX_TICK) {
            revert InvalidTickRange();
        }
        if (amount == 0) {
            revert ZeroLiquidity();
        }
        ticks.update(lowerTick, amount);
        ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(owner, lowerTick, upperTick);
        position.update(amount);

        // TODO: replace with calculation
        amount0 = 0.99897661834742528 ether;
        amount1 = 5000 ether;

        liquidity += uint128(amount);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) {
            balance0Before = balance0();
        }
        if (amount1 > 0) {
            balance1Before = balance1();
        }
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

        if (amount0 > 0 && balance0Before + amount0 > balance0()) {
            revert InsufficientInputAmount();
        }
        if (amount1 > 0 && balance1Before + amount1 > balance1()) {
            revert InsufficientInputAmount();
        }

        emit Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
    }

    /**
     * 将一定数量的代币发送到指定的接收者地址，换取一定数量的其他代币
     *
     * @param recipient 接收方地址
     * @return amount0 代币0的数量
     * @return amount1 代币1的数量
     */
    function swap(address recipient, bytes calldata data) public returns (int256 amount0, int256 amount1) {
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;

        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);

        // 给接收者发送代币
        IERC20(token0).transfer(recipient, uint256(-amount0));

        uint256 balance1Before = balance1();
        // 接收方的回调函数，让其转移代币
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
        if (balance1Before + uint256(amount1) < balance1()) {
            revert InsufficientInputAmount();
        }
        emit Swap(msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);
    }

    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}
