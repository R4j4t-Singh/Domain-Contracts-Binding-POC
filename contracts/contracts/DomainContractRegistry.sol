// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error DRC_CoolOffPeriodNotOver();

/**
 * @title Domain Contract Registry
 * @dev The Domain Contract Registry contract is used to register the dapp registry for a domain.
 */
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
  // Mapping of Chainlink request id to Domain struct
  mapping(bytes32 => Domain) private requestToDomainMap;
  // Mapping of domain to RegistryInfo struct
  mapping(string => RegistryInfo) private registryMap;
  // Mapping of domain to RecordTransition struct
  mapping(string => RecordTransition) private recordTransitionMap;

  event DappRegistryAdded(string indexed domain, address indexed dappRegistry, address indexed admin);
  event TransitionRecorded(string indexed domain, address indexed dappRegistry, address indexed admin);

  constructor() {
    // Set the address for the LINK token for the network
    setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    // Set the address of the oracle
    setChainlinkOracle(0xbF3f7C8897c93A8D440bA952a035E9e03af742bF);
    // Set the job id of the external adapter
    jobId = "2edbd7bb1fa54041b9fca33bb9400978";
    fee = (1 * LINK_DIVISIBILITY) / 10;
  }

  /**
   * @dev Set the dapp registry for a domain.
   * @notice If a domain is not registered add the dapp Registry. 
   * If a domain is already registered, and admin wants to update the dapp registry, 
   * update the registry. 
   * If a domain is already registered, and new owner wants to update the dapp registry, 
   * record transition.
   * @param _domain The domain name
   * @param _dappRegistry The address of the dapp registry
   * @return requestId The request id of the Chainlink request
  */
  function setDappRegistry(string memory _domain, address _dappRegistry) 
  external returns(bytes32){
    if(registryMap[_domain].dappRegistry == address(0) || registryMap[_domain].admin == msg.sender) {
      return _checkForDomain(_domain, _dappRegistry, this.fulfill.selector);
    }else {
      return recordTransition(_domain, _dappRegistry);
    }
  }

  /**
   * @dev Check if the contract Addresses are valid with the Dapp Registry of domain.
   * @notice Send a Chainlink request to external adapter to check if the contract Addresses 
   * are valid with the Dapp Registry of domain and send the response to callback function.
   * @param _domain The domain name
   * @param _dappRegistry The address of the dapp registry
   * @param selector The selector of the callback function to be called
   */
  function _checkForDomain(string memory _domain, address _dappRegistry, bytes4 selector) 
  internal returns(bytes32) {
    Chainlink.Request memory req = buildChainlinkRequest(
      jobId,
      address(this),
      selector
    );

    // Set the domain and dapp registry address as parameters to the request to be sent to external adapter
    req.add("domain",_domain);
    req.add("drcAddress", Strings.toHexString(uint256(uint160(_dappRegistry)), 20));

    bytes32 requestId = sendChainlinkRequest(req, fee);

    // Map the Chainlink requestId to Domain struct to be used in callback function
    requestToDomainMap[requestId].domain = _domain;
    requestToDomainMap[requestId].dappRegistry = _dappRegistry;
    requestToDomainMap[requestId].admin = msg.sender;
    return requestId;
  }

  /**
   * @dev Callback function for Chainlink request to register or update the dapp registry.
   * @notice If the response by the chainlink Oracle is true, register or update the dapp registry.
   * @param _requestId The request id of the Chainlink request
   * @param result The result of the Chainlink request
   */
  function fulfill(bytes32 _requestId, bool result) 
  public recordChainlinkFulfillment(_requestId) {
    if(result) {
      string memory domain = requestToDomainMap[_requestId].domain;
      registryMap[domain].dappRegistry = requestToDomainMap[_requestId].dappRegistry;
      registryMap[domain].admin = requestToDomainMap[_requestId].admin;

      emit DappRegistryAdded(domain, requestToDomainMap[_requestId].dappRegistry, requestToDomainMap[_requestId].admin);
    }
    delete requestToDomainMap[_requestId];
  }

  /**
   * @dev Callback function for Chainlink request to record the transition.
   * @notice If the response by the chainlink Oracle is true, record the transition.
   * @param _requestId The request id of the Chainlink request
   * @param result The result of the Chainlink request
   */
  function fulfillRecordTransiton(bytes32 _requestId, bool result) 
  public recordChainlinkFulfillment(_requestId) {
    if(result) {
      string memory domain = requestToDomainMap[_requestId].domain;
      recordTransitionMap[domain].dappRegistry = requestToDomainMap[_requestId].dappRegistry;
      recordTransitionMap[domain].timestamp = block.timestamp ;

      emit TransitionRecorded(domain, requestToDomainMap[_requestId].dappRegistry, requestToDomainMap[_requestId].admin);
    }
    delete requestToDomainMap[_requestId];
  }

  /**
   * @dev Record the transition.
   * @notice If the transition is already recorded, check if the cool off period is over. 
   * If the cool off period is over, check if the contract Addresses are valid with the Dapp 
   * registry of domain and update the registry.
   * If the transition is not recorded, check if the contract Addresses are valid with the 
   * Dapp Registry of domain and record the transition.
   * @param _domain The domain name
   * @param _dappRegistry The address of the dapp registry
   */
  function recordTransition(string memory _domain, address _dappRegistry) internal returns(bytes32) {
    if(recordTransitionMap[_domain].dappRegistry == _dappRegistry) {
      if(block.timestamp > recordTransitionMap[_domain].timestamp + 7 days) {
        return _checkForDomain(_domain, _dappRegistry, this.fulfill.selector);
      }
      else {
        revert DRC_CoolOffPeriodNotOver();
      }
    }  
    else
      return _checkForDomain(_domain, _dappRegistry, this.fulfillRecordTransiton.selector);
  }

  function getDappRegistry(string memory _domain) public view returns(address) {
    return registryMap[_domain].dappRegistry;
  }

  function getAdmin(string memory _domain) public view returns(address) {
    return registryMap[_domain].admin;
  }

  function getRecordTransition(string memory _domain) public view returns(address, uint256) {
    return (recordTransitionMap[_domain].dappRegistry, recordTransitionMap[_domain].timestamp);
  }
}