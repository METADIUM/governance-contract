// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./GovChecker.sol";
import "./interface/IStaking.sol";
import "./interface/IEnvStorage.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract TRSListImp is     
    GovChecker,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable {

    address[] public trsList;
    address[] public subscriptionList;
    mapping(address /* user address */ => uint256 /* array index, start index: 1, 0 == null */) public trsListMap;
    mapping(address /* gov member address */ => uint256 /* array index, start index: 1, 0 == null */) public subscriptionListMap;
    uint256 public updatedBlock;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    receive() external payable {}

    /* =========== FUNCTIONS ===========*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function initialize(address registry) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        setRegistry(registry);
        updatedBlock = block.number;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        emit OwnerChanged(owner(), _newOwner);
        transferOwnership(_newOwner);
     }

    function addToTRSList(address _address) public onlyOwner {
        require(trsListMap[_address] == 0, "Already exists address");
        trsList.push(_address);
        trsListMap[_address] = trsList.length;
        updatedBlock = block.number;
    }

    function removeFromTRSList(address _address) public onlyOwner {
        require(trsListMap[_address] != 0, "Address is not in the trsList");
        uint256 removeIdx = trsListMap[_address] - 1;
        if (removeIdx != trsList.length - 1) {
          trsList[removeIdx] = trsList[trsList.length - 1]; // copy last address to removeIdx
          trsListMap[trsList[trsList.length - 1]] = removeIdx + 1;
        }
        trsList.pop();
        delete trsListMap[_address];
        updatedBlock = block.number;
    }

    function addToTRSListMulti(bytes memory encodedAddresses) public onlyOwner {
        uint256 startIdx = 0;
        uint256 endIdx;
        // word(per 32 bytes): var array memory, start offset, length, data 1, 2, 3...
        assembly {
            endIdx := mload(add(encodedAddresses, /*32 * 2*/ 0x40)) // read array length
        }
        uint256 ix;
        assembly {
            ix := add(encodedAddresses, /*32 * 3*/ 0x60)
        }
        for (uint256 i = startIdx; i < endIdx; i++) {
            address currentAddress;
            assembly {
                currentAddress := mload(ix)
                ix := add(ix, /*32 * 1*/ 0x20) // ix += 32 bytes
            }
            addToTRSList(currentAddress);
        }
    }

    function removeToTRSListMulti(bytes memory encodedAddresses) public onlyOwner {
        uint256 startIdx = 0;
        uint256 endIdx;
        assembly {
            endIdx := mload(add(encodedAddresses, 0x40))
        }
        uint256 ix;
        assembly {
            ix := add(encodedAddresses, 0x60)
        }
        for (uint256 i = startIdx; i < endIdx; i++) {
            address currentAddress;
            assembly {
                currentAddress := mload(ix)
                ix := add(ix, 0x20)
            }
            removeFromTRSList(currentAddress);
        }
    }

    function subscribe() public returns (uint256) {
        require(subscriptionListMap[msg.sender] == 0, "Already exists address");

        IStaking staking = IStaking(getStakingAddress());
        uint256 amount = staking.balanceOf(msg.sender);
        require(IGov(getGovAddress()).isMember(msg.sender) || amount >= getMinStaking(), "No Permission");

        subscriptionList.push(msg.sender);
        subscriptionListMap[msg.sender] = subscriptionList.length;

        updatedBlock = block.number;

        return updatedBlock;
    }

    function unsubscribe(address _address) public returns (uint256) {
        require(subscriptionListMap[_address] != 0, "Address is not in the subscriptionList");
        require(msg.sender == _address || msg.sender == owner(), "Only oneself or the owner can call this function.");
        
        uint256 removeIdx = subscriptionListMap[_address] - 1;
        if (removeIdx != subscriptionList.length - 1) {
          subscriptionList[removeIdx] = subscriptionList[subscriptionList.length - 1]; // copy last address to removeIdx
          subscriptionListMap[subscriptionList[subscriptionList.length - 1]] = removeIdx + 1;
        }
        subscriptionList.pop();
        delete subscriptionListMap[_address];
        updatedBlock = block.number;

        return updatedBlock;
    }

    function getUpdatedBlock() public view returns (uint256) {
        return updatedBlock;
    }

    function getTRSListLength() public view returns (uint256) {
        return trsList.length;
    }

    function getTRSListAddressAtIndex(uint256 _index) public view returns (address) {
        require(_index < trsList.length, "Index out of bounds");
        return trsList[_index];
    }

    function getTRSList() public view returns (address[] memory) {
        return trsList;
    }

    function getSubscriptionListLength() public view returns (uint256) {
        return subscriptionList.length;
    }

    function getSubscriptionListAddressAtIndex(uint256 _index) public view returns (address) {
        require(_index < subscriptionList.length, "Index out of bounds");
        return subscriptionList[_index];
    }

    function getSubscriptionList() public view returns (address[] memory) {
        return subscriptionList;
    }

    function isAddressInTRSList(address _address) public view returns (bool) {
        return (trsListMap[_address] != 0);
    }

    function isAddressInSubscriptionList(address _address) public view returns (bool) {
        return (subscriptionListMap[_address] != 0);
    }

    function getMinStaking() public view returns (uint256) {
        return IEnvStorage(getEnvStorageAddress()).getStakingMin();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function upgradeTRSList(address newImp) external onlyOwner {
        if (newImp != address(0)) {
            _authorizeUpgrade(newImp);
            _upgradeToAndCallUUPS(newImp, new bytes(0), false);
        }
    }
}