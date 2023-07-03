// SPDX-License-Identifier: GPL-3.0

// Created by HashLips
// The Nerdy Coder Clones

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721x/ERC721x.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721XToken.sol";

contract GML is ERC721x, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 100 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmount = 20;
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  
  mapping(address => uint256) public lastClaim;
  uint256[] public doublingEvents;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721x(_name, _symbol) {
    setBaseURI(_initBaseURI);
    mint(msg.sender, 1, 20);
    uint256 currentTime = block.timestamp;

    // 2023: Double every month (12 times total)
    for (uint256 i = 0; i < 12; i++) {
        doublingEvents.push(currentTime + 30 days * i);
    }
    currentTime += 365 days;

    // 2024: Double every two months (6 times total)
    for (uint256 i = 0; i < 6; i++) {
        doublingEvents.push(currentTime + 60 days * i);
    }
    currentTime += 365 days;

    // 2025: Double every four months (3 times total)
    for (uint256 i = 0; i < 3; i++) {
        doublingEvents.push(currentTime + 120 days * i);
    }
    currentTime += 365 days;

    // 2026: Double every eight months (1 time total)
    doublingEvents.push(currentTime);
    currentTime += 365 days;

    // 2027-2030: Double once per year (4 times total)
    for (uint256 i = 0; i < 4; i++) {
        doublingEvents.push(currentTime + 365 days * i);
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    _mint(_to, currentTokenId, _mintAmount);
    currentTokenId++;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) 
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function claimTokens() public {
      require(balanceOf(msg.sender, currentTokenId) > 0, "No tokens to claim");
      require(lastClaim[msg.sender] < doublingEvents[doublingEvents.length - 1], "No tokens to claim");
      _mint(msg.sender, currentTokenId, balanceOf(msg.sender, currentTokenId));
      currentTokenId++;
      lastClaim[.sender] = block.timestamp;
  }

}