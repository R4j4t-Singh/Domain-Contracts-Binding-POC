// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error DRC_CoolOffPeriodNotOver();

contract DomainContractRegistry is ChainlinkClient{

  using Chainlink for Chainlink.Request;
  
  struct RegistryInfo {
    address dappRegistry;
    address admin;
  }

  struct RecordTransition {
    address dappRegistry;
    uint256 timestamp;
  }

  struct Domain {
    string domain;
    address dappRegistry;
    address admin;
  }
  
  bytes32 private jobId;
  uint256 private fee;
  mapping(bytes32 => Domain) private requestToDomainMap;
  mapping(string => RegistryInfo) public registryMap;
  mapping(string => RecordTransition) public recordTransitionMap;

  event DappRegistryAdded(string indexed domain, address indexed dappRegistry, address indexed admin);
  event TransitionRecorded(string indexed domain, address indexed dappRegistry, address indexed admin);

  constructor() {
    setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    setChainlinkOracle(0xbF3f7C8897c93A8D440bA952a035E9e03af742bF);
    jobId = "2edbd7bb1fa54041b9fca33bb9400978";
    fee = (1 * LINK_DIVISIBILITY) / 10;
  }

  function setDappRegistry(string memory _domain, address _dappRegistry) external {
    // check if a domain already has a dapp registry mapped
    // if yes, check if owner is same. if so, allow the change
    // if no, recordTransition(_domain, _dappRegistry);
      
    if(registryMap[_domain].dappRegistry != address(0) && registryMap[_domain].admin == msg.sender) {

      // Use chainlink to the call `{{domain}}/contracts.json`. 
      // Check for each contract listed in contracts.json by calling 
      // dappRegistry.isMyContract(_address)

      _checkForDomain(_domain, _dappRegistry, this.fulfill.selector);

    }else {
      recordTransition(_domain, _dappRegistry);
    }
  }

  function _checkForDomain(string memory _domain, address _dappRegistry, bytes4 selector) internal {
    Chainlink.Request memory req = buildChainlinkRequest(
      jobId,
      address(this),
      selector
    );

    req.add("domain",_domain);
    req.add("drcAddress", Strings.toHexString(uint256(uint160(_dappRegistry)), 20));

    bytes32 requestId = sendChainlinkRequest(req, fee);
    requestToDomainMap[requestId].domain = _domain;
    requestToDomainMap[requestId].dappRegistry = _dappRegistry;
    requestToDomainMap[requestId].admin = msg.sender;
  }
    
  function fulfill(bytes32 _requestId, bool result) public recordChainlinkFulfillment(_requestId) {
    
    if(result) {
      string memory domain = requestToDomainMap[_requestId].domain;
      registryMap[domain].dappRegistry = requestToDomainMap[_requestId].dappRegistry;
      registryMap[domain].admin = requestToDomainMap[_requestId].admin;

      emit DappRegistryAdded(domain, requestToDomainMap[_requestId].dappRegistry, requestToDomainMap[_requestId].admin);
    }
  }

  function fulfillRecordTransiton(bytes32 _requestId, bool result) public recordChainlinkFulfillment(_requestId) {
    if(result) {
      string memory domain = requestToDomainMap[_requestId].domain;
      recordTransitionMap[domain].dappRegistry = requestToDomainMap[_requestId].dappRegistry;
      recordTransitionMap[domain].timestamp = block.timestamp ;

      emit TransitionRecorded(domain, requestToDomainMap[_requestId].dappRegistry, requestToDomainMap[_requestId].admin);
      }
  }

  function recordTransition(string memory _domain, address _dappRegistry) internal {

    // In case of a domain transfer, register that there is potential change in registry mapping
    // and a new owner may be attempting to update registry
    // A cool-off period is applied on the domain marking a potential transfer in ownership
    // Cool-off period can be 7 days

    if(recordTransitionMap[_domain].dappRegistry == _dappRegistry) {
        if(block.timestamp > recordTransitionMap[_domain].timestamp + 7 days) {
          _checkForDomain(_domain, _dappRegistry, this.fulfill.selector);
        }
        else {
          revert DRC_CoolOffPeriodNotOver();
        }
      }  
    else
       _checkForDomain(_domain, _dappRegistry, this.fulfillRecordTransiton.selector);
  }
}