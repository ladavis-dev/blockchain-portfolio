// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockERC20.sol";

/// @title MiniExchange
/// @author Your Name
/// @notice A simplified constant product AMM for learning integrated testing
/// @dev Implements x * y = k invariant with fees
contract MiniExchange {
    // ============ State Variables ============
    
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    
    address public owner;
    uint256 public feeNumerator;
    uint256 public constant FEE_DENOMINATOR = 10000; // 0.3% = 30
    
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    
    bool private locked;
    
    // ============ Events ============
    
    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 shares
    );
    
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 shares
    );
    
    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    
    // ============ Errors ============
    
    error ZeroAmount();
    error InsufficientLiquidity();
    error InsufficientShares();
    error InvalidToken();
    error InsufficientOutput();
    error KValueDecreased();
    error TransferFailed();
    error NotOwner();
    error ReentrancyGuard();
    error InvalidFee();
    error SlippageExceeded();
    
    // ============ Modifiers ============
    
    modifier nonReentrant() {
        if (locked) revert ReentrancyGuard();
        locked = true;
        _;
        locked = false;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _tokenA, address _tokenB, uint256 _feeNumerator) {
        require(_tokenA != _tokenB, "Identical tokens");
        require(_feeNumerator <= 100, "Fee too high"); // Max 1%
        
        tokenA = MockERC20(_tokenA);
        tokenB = MockERC20(_tokenB);
        feeNumerator = _feeNumerator;
        owner = msg.sender;
    }
    
    // ============ Core Functions ============
    
    /// @notice Add liquidity to the pool
    /// @param amountA Amount of token A to add
    /// @param amountB Amount of token B to add
    /// @return sharesToMint Number of LP shares minted
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external nonReentrant returns (uint256 sharesToMint) {
        if (amountA == 0 || amountB == 0) revert ZeroAmount();
        
        // Transfer tokens to contract
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        if (totalShares == 0) {
            // First liquidity provider
            sharesToMint = _sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            // Lock minimum liquidity forever
            shares[address(0)] = MINIMUM_LIQUIDITY;
            totalShares = MINIMUM_LIQUIDITY;
        } else {
            // Subsequent providers - mint proportional shares
            uint256 shareA = (amountA * totalShares) / reserveA;
            uint256 shareB = (amountB * totalShares) / reserveB;
            sharesToMint = shareA < shareB ? shareA : shareB;
        }
        
        if (sharesToMint == 0) revert InsufficientLiquidity();
        
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, sharesToMint);
    }
    
    /// @notice Remove liquidity from the pool
    /// @param sharesToBurn Number of LP shares to burn
    /// @return amountA Amount of token A returned
    /// @return amountB Amount of token B returned
    function removeLiquidity(
        uint256 sharesToBurn
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        if (sharesToBurn == 0) revert ZeroAmount();
        if (shares[msg.sender] < sharesToBurn) revert InsufficientShares();
        
        // Calculate proportional amounts
        amountA = (sharesToBurn * reserveA) / totalShares;
        amountB = (sharesToBurn * reserveB) / totalShares;
        
        if (amountA == 0 || amountB == 0) revert InsufficientLiquidity();
        
        // Update state
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, sharesToBurn);
    }
    
    /// @notice Swap tokens
    /// @param tokenIn Address of input token
    /// @param amountIn Amount of input token
    /// @param minAmountOut Minimum output (slippage protection)
    /// @return amountOut Amount of output token
    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) external nonReentrant returns (uint256 amountOut) {
        if (amountIn == 0) revert ZeroAmount();
        
        bool isTokenA = tokenIn == address(tokenA);
        bool isTokenB = tokenIn == address(tokenB);
        
        if (!isTokenA && !isTokenB) revert InvalidToken();
        
        (
            MockERC20 inputToken,
            MockERC20 outputToken,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isTokenA 
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);
        
        // Transfer input token
        inputToken.transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate output with fee
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - feeNumerator);
        amountOut = (amountInWithFee * reserveOut) / 
                    (reserveIn * FEE_DENOMINATOR + amountInWithFee);
        
        if (amountOut < minAmountOut) revert SlippageExceeded();
        if (amountOut == 0) revert InsufficientOutput();
        
        // Verify k invariant (should increase due to fees)
        uint256 kBefore = reserveA * reserveB;
        
        // Update reserves
        if (isTokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
        
        uint256 kAfter = reserveA * reserveB;
        if (kAfter < kBefore) revert KValueDecreased();
        
        // Transfer output token
        outputToken.transfer(msg.sender, amountOut);
        
        emit Swap(msg.sender, tokenIn, address(outputToken), amountIn, amountOut);
    }
    
    /// @notice Get expected output amount
    /// @param tokenIn Input token address
    /// @param amountIn Input amount
    /// @return amountOut Expected output amount
    function getAmountOut(
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        if (amountIn == 0) return 0;
        
        bool isTokenA = tokenIn == address(tokenA);
        if (!isTokenA && tokenIn != address(tokenB)) return 0;
        
        uint256 reserveIn = isTokenA ? reserveA : reserveB;
        uint256 reserveOut = isTokenA ? reserveB : reserveA;
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - feeNumerator);
        amountOut = (amountInWithFee * reserveOut) / 
                    (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }
    
    /// @notice Get expected input amount for desired output
    /// @param tokenOut Output token address
    /// @param amountOut Desired output amount
    /// @return amountIn Required input amount
    function getAmountIn(
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        if (amountOut == 0) return 0;
        
        bool isTokenA = tokenOut == address(tokenA);
        if (!isTokenA && tokenOut != address(tokenB)) return 0;
        
        uint256 reserveIn = isTokenA ? reserveB : reserveA;
        uint256 reserveOut = isTokenA ? reserveA : reserveB;
        
        if (amountOut >= reserveOut) return type(uint256).max;
        
        amountIn = (reserveIn * amountOut * FEE_DENOMINATOR) / 
                   ((reserveOut - amountOut) * (FEE_DENOMINATOR - feeNumerator)) + 1;
    }
    
    /// @notice Get current price of token A in terms of token B
    function getPrice() external view returns (uint256) {
        if (reserveA == 0) return 0;
        return (reserveB * 1e18) / reserveA;
    }
    
    /// @notice Get the k value (product of reserves)
    function getK() external view returns (uint256) {
        return reserveA * reserveB;
    }
    
    // ============ Admin Functions ============
    
    /// @notice Update swap fee
    function setFee(uint256 _newFee) external onlyOwner {
        if (_newFee > 100) revert InvalidFee();
        
        uint256 oldFee = feeNumerator;
        feeNumerator = _newFee;
        
        emit FeeUpdated(oldFee, _newFee);
    }
    
    // ============ Internal Functions ============
    
    /// @notice Calculate square root using Babylonian method
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
