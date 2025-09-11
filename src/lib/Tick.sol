// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @title Tick信息
 */
library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(mapping(int24 => Info) storage self, int24 tick, uint128 liquidityDelta) internal {
        Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }
        tickInfo.liquidity = liquidityAfter;
    }
}
