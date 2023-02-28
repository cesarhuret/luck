// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";

interface IMidpoint {

    function callMidpoint(uint64 midpointId, bytes calldata _data) external returns(uint64 requestId);

}

contract Lucky is ERC20 {

    address devAddress;
    bytes32 private jobId;
    uint256 private fee;

    address immutable startpointAddress;

    address immutable whitelistedCallbackAddress;

    uint64 constant midpointID = 663;

    struct Tx {
        address to;
        uint256 amt;
    }

    mapping(uint64 => Tx) private txns;

    constructor(address _startpointAddress, address _whitelistedCallbackAddress) ERC20("LUCKY", "$LUCK") {
        startpointAddress = _startpointAddress;
        whitelistedCallbackAddress = _whitelistedCallbackAddress;
        _mint(msg.sender, 1000000000 * 1e18);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        bytes memory args = abi.encodePacked(uint256(0), (amount*4)/1e18);
        
        // This makes the call to your midpoint
        uint64 Request_ID = IMidpoint(startpointAddress).callMidpoint(midpointID, args);

        txns[Request_ID] = Tx(to, amount);

        emit Transfer(from, to, amount);
    }

    function callback(uint64 Request_ID, uint64 Midpoint_ID, uint256 random) public {
        // Only allow a verified callback address to submit information for your midpoint.
        require(tx.origin == whitelistedCallbackAddress, "Invalid callback address");
        // Only allow requests that came from your midpoint ID
        require(midpointID == Midpoint_ID, "Invalid Midpoint ID");
        
        Tx memory txn = txns[Request_ID];

        (address to, uint256 amount) = (txn.to, txn.amt);

        _balances[to] += random * 1e18;

        uint256 newAmt = (random * 1e18) - amount;

        if(random * 1e18 > amount) {
            _totalSupply += newAmt;
            emit Transfer(address(0), to, newAmt);
        } else if (random * 1e18 < amount) {
            _totalSupply -= newAmt;
            emit Transfer(to, address(0), newAmt);
        }
    }

}