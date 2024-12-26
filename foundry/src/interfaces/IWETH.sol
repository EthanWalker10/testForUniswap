// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "./IERC20.sol";

// weth 合约中有对应的实现
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}
