pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title PausableERC20
 */
contract PausableERC20 is ERC20, Ownable {
    event Paused();
    event Unpaused();

    bool private _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "not paused");
        _;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by the owner to pause, triggers stopped state
     * @return A boolean that indicates if the operation was successful.
     */
    function pause() public
    onlyOwner
    whenNotPaused
    returns (bool) {
        _paused = true;
        emit Paused();
        return true;
    }

    /**
     * @dev Called by the owner to unpause, returns to normal state
     * @return A boolean that indicates if the operation was successful.
     */
    function unpause() public
    onlyOwner
    whenPaused
    returns (bool) {
        _paused = false;
        emit Unpaused();
        return true;
    }
}
