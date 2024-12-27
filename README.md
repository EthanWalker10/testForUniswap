# Uniswap v2

## 数学推导
### 1. Swap Math
1. 推导公式: 根据输入的 dx(新增的 token0 数量), 得到 dy(置换出的 token1 数量)
   1. 建立等式: x0 * y0 = (x0+dx) * (y0-dy)
   2. 化简得: dy = (y0 * dx) / (x0 + dx)

### 2. Swap Fee
1. swap fee 是在输入 token 里按照费率 f 收取的, 也就是说: swap fee = f * dx; 也就是说, dx 在实际中是由损失的, 将这个等式带入之前的等式得到:
   1. dy = dx(1 - f) * y0 / (x0 + dx(1 - f))


## swap()
```solidity
// 乐观转账, 转完帐才校验, 为闪电贷留下空间;
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
   require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
   (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
   require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

   uint balance0;
   uint balance1;
   { // scope for _token{0,1}, avoids stack too deep errors
   address _token0 = token0;
   address _token1 = token1;
   require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
   if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
   if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
   if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data); // 回调自己合约的闪电贷逻辑
   balance0 = IERC20(_token0).balanceOf(address(this));
   balance1 = IERC20(_token1).balanceOf(address(this));
   }
   uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
   uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
   require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
   { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
   uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
   uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
   require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
   }

   _update(balance0, balance1, _reserve0, _reserve1);
   emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
}
```