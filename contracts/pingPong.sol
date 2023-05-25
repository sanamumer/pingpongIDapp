//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/Utils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PingPong {
      address public owner;
      uint64 public currentRequestId;

  // srcChainId + requestId => pingFromSource
  mapping(string => mapping(uint64 => string)) public pingFromSource;
  // requestId => ackMessage
  mapping(uint64 => string) public ackFromDestination;

  // instance of the Router's gateway contract
  IGateway public gatewayContract;

  // event we will emit while sending a ping to destination chain
  event PingFromSource(
    string indexed srcChainId,
    uint64 indexed requestId,
    string message
  );
  event NewPing(uint64 indexed requestId);

  constructor(address payable gatewayAddress, string memory feePayerAddress) {
    owner = msg.sender;

    gatewayContract = IGateway(gatewayAddress);

    gatewayContract.setDappMetadata(feePayerAddress);
  }

  function setDappMetadata(
    string memory FeePayer
    ) public {
    require(msg.sender == owner, "Only owner can set the metadata");
    gatewayContract.setDappMetadata(FeePayer);
  }

  function iPing(
    string calldata destChainId,
    string calldata destinationContractAddress,
    string calldata str,
    bytes calldata requestMetadata
  ) public payable {
    currentRequestId++;

    bytes memory packet = abi.encode(currentRequestId, str);
    bytes memory requestPacket = abi.encode(destinationContractAddress, packet);
    gatewayContract.iSend{ value: msg.value }(
      1,
      0,
      string(""),
      destChainId,
      requestMetadata,
      requestPacket
    );
    emit NewPing(currentRequestId);
  }

  function getRequestMetadata(
     uint64 destGasLimit,
     uint64 destGasPrice,
     uint64 ackGasLimit,
     uint64 ackGasPrice,
     uint128 relayerFees,
     uint8 ackType,
     bool isReadCall,
     bytes memory asmAddress
   ) public pure returns (bytes memory) {
     bytes memory requestMetadata = abi.encodePacked(
       destGasLimit,
       destGasPrice,
       ackGasLimit,
       ackGasPrice,
       relayerFees,
       ackType,
       isReadCall,
       asmAddress
     );
     return requestMetadata;
   }

  function iReceive(
  string memory requestSender,
  bytes memory packet,
  string memory srcChainId
) external returns (uint64, string memory) {
  require(msg.sender == address(gatewayContract), "only gateway");
  (uint64 requestId, string memory sampleStr) = abi.decode(
    packet,
    (uint64, string)
  );
  pingFromSource[srcChainId][requestId] = sampleStr;

  emit PingFromSource(srcChainId, requestId, sampleStr);

  return (requestId, sampleStr);
}

  function iAck(
  uint256 requestIdentifier,
  bool execFlag,
  bytes memory execData
) external {
  (uint64 requestId, string memory ackMessage) = abi.decode(
    execData,
    (uint64, string)
  );

  ackFromDestination[requestId] = ackMessage;
}

}