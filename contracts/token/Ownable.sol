pragma solidity ^0.4.24;
import "zos-lib/contracts/Initializable.sol";

/**
 * @title Ownable
 */
contract Ownable is Initializable {
    address public owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not called by owner");
        _;
    }

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address _owner) public initializer {
        owner = _owner;
    }
}
