# Uniswap v2

## 数学推导
### 1. Swap Math
1. 推导公式: 根据输入的 dx(新增的 token0 数量), 得到 dy(置换出的 token1 数量)
   1. 建立等式: x0 * y0 = (x0+dx) * (y0-dy)
   2. 化简得: dy = (y0 * dx) / (x0 + dx)

### 2. Swap Fee
1. swap fee 是在输入 token 里按照费率 f 收取的, 也就是说: swap fee = f * dx; 也就是说, dx 在实际中是由损失的, 将这个等式带入之前的等式得到:
   1. dy = dx(1 - f) * y0 / (x0 + dx(1 - f))