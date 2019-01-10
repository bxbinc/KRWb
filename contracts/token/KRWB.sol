pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20WithFees.sol";
import "./ERC20WithBlacklist.sol";
import "./PausableERC20.sol";
import "./BurnableERC20.sol";
import "./MintableERC20.sol";

/**
 * @title KRWb is a stable token backed 100% by KRW. 1-to-1 ratio of KRWb to KRW sitting in a transparent and audited Korean bank account.
 */
contract KRWb is ERC20, Ownable, ERC20Detailed, ERC20WithFees, ERC20WithBlacklist, PausableERC20, BurnableERC20, MintableERC20 {
    using SafeMath for uint256;

    function initialize(address _owner) initializer public {
        require(_owner != address(0), "owner is zero");

        Ownable.initialize(_owner);
        ERC20Detailed.initialize("KRWb Token", "KRWb", 2);
        ERC20WithFees.initialize(_owner);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public
    whenNotPaused
    notBlacklisted(msg.sender)
    returns (bool) {
        bool transferred = super.transfer(to, value);
        uint256 transferFee = calculateTransferFee(msg.sender, value);
        if (transferFee > 0) {
            _transfer(to, transferFeeReceiver, transferFee);
        }
        return transferred;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public
    whenNotPaused
    notBlacklisted(msg.sender)
    returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public
    whenNotPaused
    notBlacklisted(msg.sender)
    returns (bool) {
        bool transferred = super.transferFrom(from, to, value);
        uint256 transferFee = calculateTransferFee(from, value);
        if (transferFee > 0) {
            _transfer(to, transferFeeReceiver, transferFee);
        }
        return transferred;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public
    whenNotPaused
    notBlacklisted(msg.sender)
    returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public
    whenNotPaused
    notBlacklisted(msg.sender)
    returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public whenNotPaused returns (bool) {
        return super.mint(to, amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the owner account and decrements allowance
     * @param amount uint256 The amount of token to be burned
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 amount) public whenNotPaused returns (bool) {
        return super.burn(amount);
    }
}
