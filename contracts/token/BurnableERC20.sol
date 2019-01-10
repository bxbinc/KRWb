pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title BurnableERC20
 */
contract BurnableERC20 is ERC20, Ownable {
    uint256 public burnMin;
    uint256 public burnMax;

    event Burned(address from, uint256 amount);
    event SetBurnBounds(uint256 min, uint256 max);

    /**
     * @dev Burns a specific amount of tokens from the owner account and decrements allowance
     * @param amount uint256 The amount of token to be burned
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 amount) onlyOwner public returns (bool) {
        require(amount >= burnMin, "amount to burn is smaller than burnMin");
        require(burnMax == 0 || amount <= burnMax, "amount to burn is greater than burnMax");
        _burn(owner, amount);
        emit Burned(owner, amount);
        return true;
    }

    /**
     * @param min uin256 Minimum amount of tokens that can be burnt
     * @param max uin256 Maximum amount of tokens that can be burnt
     */
    function setBurnBounds(uint256 min, uint256 max) public onlyOwner {
        require(min <= max, "min must be smaller than max");
        burnMin = min;
        burnMax = max;
        emit SetBurnBounds(min, max);
    }
}
