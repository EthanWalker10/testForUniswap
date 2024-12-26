// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {
    DAI,
    WETH,
    MKR,
    UNISWAP_V2_PAIR_DAI_MKR,
    UNISWAP_V2_ROUTER_02
} from "../../../src/Constants.sol";

contract UniswapV2SwapTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);

    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair =
        IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_MKR);

    address private constant user = address(100);

    function setUp() public {
        // 设置一个允许 router 使用 100 weth 的账户
        deal(user, 100 * 1e18);
        vm.startPrank(user);
        weth.deposit{value: 100 * 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // 将 DAI 和 MKR 添加到 pair 中
        deal(DAI, address(pair), 1e6 * 1e18);
        deal(MKR, address(pair), 1e5 * 1e18);
        pair.sync();
    }

    // 将确定数量的 WETH 尽可能多的兑换成 MKR
    function test_swapExactTokensForTokens() public {
        // 构造多跳路径
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18;
        uint256 amountOutMin = 1;

        vm.prank(user);
        uint256[] memory amounts = router.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        assertGe(mkr.balanceOf(user), amountOutMin, "MKR balance of user");
    }

    // 以尽可能少的 WETH 置换到确定数量的 MKR
    function test_swapTokensForExactTokens() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 0.1 * 1e18;
        uint256 amountInMax = 1e18;

        vm.prank(user);
        uint256[] memory amounts = router.swapTokensForExactTokens({
            amountOut: amountOut,
            amountInMax: amountInMax,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        assertEq(mkr.balanceOf(user), amountOut, "MKR balance of user");
    }
}
