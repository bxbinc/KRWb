pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title MintableERC20
 */
contract MintableERC20 is ERC20, Ownable {
    uint256 public mintMin;
    uint256 public mintMax;

    event Minted(address to, uint256 amount);
    event SetMintBounds(uint256 min, uint256 max);

    address[] private _mintWhitelist;

    event AddedToMintWhitelist(address addr);
    event RemovedFromMintWhitelist(address addr);

    /**
     * @dev Throws if addr is not mint-whitelisted.
     */
    modifier mintWhitelisted(address addr) {
        require(isMintWhitelisted(addr), "addr is not mint-whitelisted");
        _;
    }

    /**
     * @param addr The address to check if mint-whitelisted
     * @return true if addr is mint-whitelisted, false otherwise
     */
    function isMintWhitelisted(address addr) public view returns (bool) {
        for (uint i = 0; i < _mintWhitelist.length; i++) {
            if (_mintWhitelist[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Function to add an address to the mint-whitelist
     * @param addr The address to add to the mint-whitelist
     * @return A boolean that indicates if the operation was successful.
     */
    function addToMintWhitelist(address addr) public onlyOwner returns (bool) {
        require(!isMintWhitelisted(addr), "addr is already mint-whitelisted");
        _mintWhitelist.push(addr);
        emit AddedToMintWhitelist(addr);
        return true;
    }

    /**
     * @dev Function to remove an address from the mint-whitelist
     * @param addr The address to remove from the mint-whitelist
     * @return A boolean that indicates if the operation was successful.
     */
    function removeFromMintWhitelist(address addr) public onlyOwner returns (bool) {
        require(isMintWhitelisted(addr), "addr is not mint-whitelisted");
        for (uint i = 0; i < _mintWhitelist.length; i++) {
            if (_mintWhitelist[i] == addr) {
                _mintWhitelist[i] = _mintWhitelist[_mintWhitelist.length - 1];
                _mintWhitelist.length -= 1;
                break;
            }
        }
        emit RemovedFromMintWhitelist(addr);
        return true;
    }

    /**
     * @return Length of the mint-whitelist
     */
    function getMintWhitelistLength() public view returns (uint) {
        return _mintWhitelist.length;
    }

    /**
     * @return MintWhitelisted address at index
     */
    function getMintWhitelist(uint index) public view returns (address) {
        return _mintWhitelist[index];
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public
    onlyOwner
    mintWhitelisted(to)
    returns (bool) {
        require(amount >= mintMin, "amount to mint is smaller than mintMin");
        require(mintMax == 0 || amount <= mintMax, "amount to mint is greater than mintMax");
        _mint(to, amount);
        emit Minted(to, amount);
        return true;
    }

    /**
     * @param min uin256 Minimum amount of tokens that can be minted
     * @param max uin256 Maximum amount of tokens that can be minted
     */
    function setMintBounds(uint256 min, uint256 max) public onlyOwner {
        require(min <= max, "min must be smaller than max");
        mintMin = min;
        mintMax = max;
        emit SetMintBounds(min, max);
    }
}
