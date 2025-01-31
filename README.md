# Uniswap v2

## 数学推导
### 1. Swap Math
1. 推导公式: 根据输入的 dx(新增的 token0 数量), 得到 dy(置换出的 token1 数量)
   1. 建立等式: x0 * y0 = (x0+dx) * (y0-dy)
   2. 化简得: dy = (y0 * dx) / (x0 + dx)

### 2. Swap Fee
1. swap fee 是在输入 token 里按照费率 f 收取的, 也就是说: swap fee = f * dx; 也就是说, dx 在实际中是由损失的, 将这个等式带入之前的等式得到:
   1. dy = dx(1 - f) * y0 / (x0 + dx(1 - f))


### 3. Pool Shares Mint
1. 推导过程: 
   1. L0: add 前的流动性; L1: add 后的流动性; T: 当前 shares 总额; S: 待计算的需要增加的 shares
   2. 建立等式: L1/L0 = (T+S)/T
   3. S = (L1-L0)/L0 * T  **公式1**
2. 例子: 初始有 1000 tokens, 共 1000 shares, 后来获得收益, 变为 1100 tokens. 但是此时仍然是 1000 shares, 说明 shares 只与 LP 新增/删除的 liquidity 有关, 自己带来的收益不影响 shares. 然后新的 LP 提供 110 个 tokens, 按照上面的计算得, 应该新增 100 shares. 可以看到, 在池子早期, 只需要 100 tokens 就可以获取 100 shares, 现在则需要 110 tokens.

### 4. Pool shares Burn
1. burn 多少自己的 shares 都可以，关键是计算 burn shares 之后能取出多少 token：
   1. 取出 token 数：shares burnt / total shares * 总锁仓 token 数


### 5. Pool shares Burn
1. burn 多少自己的 shares 都可以，关键是计算 burn shares 之后能取出多少 token：
   1. 取出 token 数：shares burnt / total shares * 总锁仓 token 数


### 6. Add Liq Graph
1. 进入 pair 中, 情况变成两种 token. shares 的计算就分成两种 token 来计算就可以, 但是要注意, add liquidity 的时候, 并不是能够随意提供数量的, 否则存在恶意操控价格的风险. 换句话说, 提供的 dx 和 dy 仍然需要满足不变性
2. dy/dx = y0/x0  **公式2**


### 7. Add Liq Pool Shares
基于前述知识推导在 pair/pool 中的 shares 计算
1. (L1-L0)/L0 = dx/x0 = dy/y0  **公式3**
2. Pool Value，以 F(x,y) 表示, 分别计算基于 token0 和 token 1 的价值
   1. 以 token0 来定义：token1 的总价值为 y * (x/y) = x; F(x,y) = 2x
   2. 同样的, 以 token1 来表示: F(x,y) = 2y
3. 将 **公式3** 代入 **公式1** 得到: S = dx / x0 * T = dy / y0 * T  **公式4**
4. 也就是说, add liquidity 之后, 需要增加的 shares 就等于 dx / x0 或者 dy / y0 倍原有 shares(dx 和 dy 需要满足上面的关系)

### 8. Remove Liquidity
1. 逻辑类似于 Add Liquidity


### 9. Flash Swap Math
1. Flash Swap Fee Equation: x0是 pool 中的 tokenX 的数量, dx0 是借走的数量, dx1 是还的数量. 关键是计算 Flash Swap Fee
   1. x0 - dx0 + 0.997 dx1 >= x0; 也就是说, 借贷费用至少需要超过 0.3% 的手续费
   2. dx1 = dx0 + fee
   3. 结合上述两式得: 0.997 fee >= 0.003 dx0
2. flashSwap 底层同样是在 swap 函数中实现的, 通过 calldata 数据来调用借贷者合约的函数(需要实现 uniswapV2Call ), 在该函数中实现自己的盈利逻辑


### 10. Twap
1. Tk 到 Tn 离散时间点的价格加权平均计算: = Σ( i = k to n - 1 ) Δ of Ti * Pi / Tn - Tk
2. 引入一个 state variable Cj(cumulative, 累积的) 来表示: Σ( i = 0 to j - 1 ) Δ of Ti * Pi
3. 将公式简化为: TWAP from tk to tn = (Cn - Ck) / (tn - tk)



## functions

### swap()
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


## Add Liq Contract Call
1. router.addLiquidity 函数的作用:
   1. 用户调用, router 查看对应的 pool 是否存在
   2. 如果不存在, factory 使用 createPair 函数部署一个
   3. router 合约将 tokens 由用户转给 pair/pool
   4. router 调用 pair 的 mint 函数
   5. pair 计算决定为用户 mint 多少 LP tokens 代表用户的 shares


## 15. Add Liq  code walk - quote()
1. 用于根据 token0 的数量计算适当的 token1 的数量, 核心公式: dy = dx * (y/x)


## 16. Add Liq  code walk - Mint
1. 用于为 Lp 铸造 shares
2. 如果池子的 totalSupply 为0, 那么需要采取 MINIMUM_LIQUIDITY 机制, 确保铸造的 liquidity 至少大于这个值, 这个流动性将被锁住, 防范 vault inflation attack



## Arb(Arbitrage, 套利)
1. 两种策略:
   1. With Capital
   2. With Flash Swaps