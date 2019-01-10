pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title ERC20WithFees
 */
contract ERC20WithFees is ERC20, Ownable {

    struct Fee {
        uint256 numerator;
        uint256 denominator;
    }

    address public transferFeeReceiver;
    Fee private _transferFee;
    mapping(address => Fee) _individualTransferFee;

    event SetTransferFeeReceiver(address transferFeeReceiver);
    event SetTransferFee(uint256 numerator, uint256 denominator);
    event SetIndividualTransferFee(address addr, uint256 numerator, uint256 denominator);

    function initialize(address _transferFeeReceiver) initializer public {
        require(_transferFeeReceiver != address(0), "_transferFeeReceiver is zero");

        transferFeeReceiver = _transferFeeReceiver;
    }

    /**
     * @dev Sets transferFeeReceiver.
     */
    function setTransferFeeReceiver(address receiver) public onlyOwner {
        require(receiver != address(0), "receiver is zero");
        transferFeeReceiver = receiver;
        emit SetTransferFeeReceiver(receiver);
    }

    /**
     * @return Numerator of transferFee.
     */
    function transferFeeNumerator() public view returns (uint256) {
        return _transferFee.numerator;
    }

    /**
     * @return Denominator of transferFee.
     */
    function transferFeeDenominator() public view returns (uint256) {
        return _transferFee.denominator;
    }

    /**
     * @dev Sets transferFee.
     */
    function setTransferFee(uint256 numerator, uint256 denominator) public onlyOwner {
        require(numerator < denominator, "numerator is equal to or greater than denominator");
        _transferFee = Fee(numerator, denominator);
        emit SetTransferFee(numerator, denominator);
    }

    /**
     * @return Numerator of addr's transferFee.
     */
    function individualTransferFeeNumerator(address addr) public view returns (uint256) {
        return _individualTransferFee[addr].numerator;
    }

    /**
     * @return Denominator of addr's transferFee.
     */
    function individualTransferFeeDenominator(address addr) public view returns (uint256) {
        return _individualTransferFee[addr].denominator;
    }

    /**
     * @dev Sets individual's transferFeeNumerator and transferFeeDenominator. Its precedence is higher than global transfer feel.
     */
    function setIndividualTransferFee(address addr, uint256 numerator, uint256 denominator) public onlyOwner {
        require(numerator < denominator, "numerator is equal to or greater than denominator");
        _individualTransferFee[addr].numerator = numerator;
        _individualTransferFee[addr].denominator = denominator;
        emit SetIndividualTransferFee(addr, numerator, denominator);
    }

    /**
     * @return Calculated transfer fee for the given value.
     */
    function calculateTransferFee(address sender, uint256 value) internal view returns (uint256) {
        if (_individualTransferFee[sender].denominator > 0) {
            return value.mul(_individualTransferFee[sender].numerator).div(_individualTransferFee[sender].denominator);
        } else {
            if (_transferFee.denominator > 0) {
                return value.mul(_transferFee.numerator).div(_transferFee.denominator);
            } else {
                return 0;
            }
        }
    }
}
