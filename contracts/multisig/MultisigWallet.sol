pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";

/**
 * @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
 */
contract MultisigWallet is Initializable {

    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Invalidation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    uint constant public MAX_OWNER_COUNT = 50;

    mapping(uint => Transaction) public transactions;
    mapping(uint => bool) public invalidated;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 submittedAt;
        uint256 expiredAt;
        string memo;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this), "not called by wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "called by an owner");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "not called by an onwer");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].to != 0, "transaction for transactionId doesn't exist");
        _;
    }

    modifier transactionNotExpired(uint transactionId) {
        uint expiredAt = transactions[transactionId].expiredAt;
        require(expiredAt == 0 || expiredAt > now, "transaction for transactionId expired");
        _;
    }

    modifier notInvalidated(uint transactionId) {
        require(!invalidated[transactionId], "transaction already invalidated");
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner], "transaction not confirmed");
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "transaction already confirmed");
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "transaction already executed");
        _;
    }

    modifier notNull(address addr) {
        require(addr != 0, "address is zero");
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
            _required <= ownerCount &&
            _required != 0 &&
            ownerCount != 0,
            "not a valid requirement condition"
        );
        _;
    }

    /**
     * @dev Fallback function allows to deposit ether.
     */
    function() public payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /**
     * @dev Contract constructor sets initial owners and required number of confirmations.
     * @param _owners List of initial owners.
     * @param _required Number of required confirmations.
     */
    function initialize(address[] _owners, uint _required) public
    validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0, "owner is duplicate or the address is zero");
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /**
     * @dev Allows to add a new owner. Transaction has to be sent by wallet.
     * @param owner Address of new owner.
     */
    function addOwner(address owner) public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required) {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /**
     * @dev Allows to remove an owner. Transaction has to be sent by wallet.
     * @param owner Address of owner.
     */
    function removeOwner(address owner) public
    onlyWallet
    ownerExists(owner) {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        require(owners.length > 0, "owners should not be empty");
        emit OwnerRemoval(owner);
    }

    /**
     * @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
     * @param owner Address of owner to be replaced.
     * @param newOwner Address of new owner.
     */
    function replaceOwner(address owner, address newOwner) public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
    notNull(newOwner) {
        require(owner != newOwner, "newOwner must be different from owner");
        for (uint i = 0; i < owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /**
     * @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     * @param _required Number of required confirmations.
     */
    function changeRequirement(uint _required) public
    onlyWallet
    validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

    /**
     * @dev Allows an owner to submit and confirm a transaction.
     * @param to Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @param expiredAt Timestamp of expiration. 0 indicates no expiration.
     * @param memo Indication of what this transaction is about.
     * @return Returns transaction ID.
     */
    function submitTransaction(address to, uint value, bytes data, uint expiredAt, string memo) public returns (uint transactionId) {
        transactionId = addTransaction(to, value, data, expiredAt, memo);
        confirmTransaction(transactionId);
    }

    /**
     * @dev Allows an owner to invalidate a transaction, if it hasn't been confirmed.
     * @param transactionId Transaction ID.
     */
    function invalidateTransaction(uint transactionId) public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    transactionNotExpired(transactionId)
    notInvalidated(transactionId)
    notExecuted(transactionId) {
        invalidated[transactionId] = true;
        emit Invalidation(msg.sender, transactionId);
    }

    /**
     * @dev Allows an owner to confirm a transaction.
     * @param transactionId Transaction ID.
     */
    function confirmTransaction(uint transactionId) public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    transactionNotExpired(transactionId)
    notInvalidated(transactionId)
    notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * @dev Allows an owner to revoke a confirmation for a transaction.
     * @param transactionId Transaction ID.
     */
    function revokeConfirmation(uint transactionId) public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    transactionNotExpired(transactionId)
    notInvalidated(transactionId)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * @dev Allows anyone to execute a confirmed transaction.
     * @param transactionId Transaction ID.
     */
    function executeTransaction(uint transactionId) public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    transactionNotExpired(transactionId)
    notInvalidated(transactionId)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.to, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address to, uint value, uint dataLength, bytes data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 34710), // 34710 is the value that solidity is currently emitting
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the to address does not exist and needs creating)
            to,
            value,
            d,
            dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /**
     * @dev Returns the confirmation status of a transaction.
     * @param transactionId Transaction ID.
     * @return Confirmation status.
     */
    function isConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     * @param to Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @param expiredAt Timestamp of expiration. 0 indicates no expiration.
     * @param memo Indication of what this transaction is about.
     * @return Returns transaction ID.
     */
    function addTransaction(address to, uint value, bytes data, uint expiredAt, string memo) internal
    notNull(to)
    returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            to : to,
            value : value,
            data : data,
            submittedAt : now,
            expiredAt : expiredAt,
            memo : memo,
            executed : false
            });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /**
     * @dev Returns number of confirmations of a transaction.
     * @param transactionId Transaction ID.
     * @return Number of confirmations.
     */
    function getConfirmationCount(uint transactionId) public view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    /**
     * @dev Returns total number of transactions after filers are applied.
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return Total number of transactions after filters are applied.
     */
    function getTransactionCount(bool pending, bool executed) public view returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
        }
    }

    /**
     * @dev Returns list of owners.
     * @return List of owner addresses.
     */
    function getOwners() public view returns (address[]) {
        return owners;
    }

    /**
     * @dev Returns array with owner addresses, which confirmed transaction.
     * @param transactionId Transaction ID.
     * @return Returns array of owner addresses.
     */
    function getConfirmations(uint transactionId) public view returns (address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /**
     * @dev Returns list of transaction IDs in defined range.
     * @param from Index start position of transaction array.
     * @param to Index end position of transaction array.
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return Returns array of transaction IDs.
     */
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}
