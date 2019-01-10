pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title ERC20WithBlacklist
 */
contract ERC20WithBlacklist is ERC20, Ownable {
    address[] private _blacklist;

    event AddedToBlacklist(address addr);
    event RemovedFromBlacklist(address addr);

    /**
     * @dev Throws if addr is blacklisted.
     */
    modifier notBlacklisted(address addr) {
        require(!isBlacklisted(addr), "addr is blacklisted");
        _;
    }

    /**
     * @param addr The address to check if blacklisted
     * @return true if addr is blacklisted, false otherwise
     */
    function isBlacklisted(address addr) public view returns (bool) {
        for (uint i = 0; i < _blacklist.length; i++) {
            if (_blacklist[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Function to add an address to the blacklist
     * @param addr The address to add to the blacklist
     * @return A boolean that indicates if the operation was successful.
     */
    function addToBlacklist(address addr) onlyOwner public returns (bool) {
        require(!isBlacklisted(addr), "addr is already blacklisted");
        _blacklist.push(addr);
        emit AddedToBlacklist(addr);
        return true;
    }

    /**
     * @dev Function to remove an address from the blacklist
     * @param addr The address to remove from the blacklist
     * @return A boolean that indicates if the operation was successful.
     */
    function removeFromBlacklist(address addr) onlyOwner public returns (bool) {
        require(isBlacklisted(addr), "addr is not blacklisted");
        for (uint i = 0; i < _blacklist.length; i++) {
            if (_blacklist[i] == addr) {
                _blacklist[i] = _blacklist[_blacklist.length - 1];
                _blacklist.length -= 1;
                break;
            }
        }
        emit RemovedFromBlacklist(addr);
        return true;
    }

    /**
     * @return Length of the blacklist
     */
    function getBlacklistLength() public view returns (uint) {
        return _blacklist.length;
    }

    /**
     * @return Blacklisted address at index
     */
    function getBlacklist(uint index) public view returns (address) {
        return _blacklist[index];
    }
}
