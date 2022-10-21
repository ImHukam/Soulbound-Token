// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

bytes32 constant AGREEMENT_HASH =
  keccak256(
    "Agreement(address active,address passive,string tokenURI)"
);

contract SoulBound is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private _usedHashes;

  string private _name = "SoulBound";
  string private _symbol= "SBT";
  string private _version= "1";

  mapping(uint256 => address) private _owners;
  mapping(uint256 => string) private _tokenURIs;
  mapping(address => uint256) private _balances;

  constructor() EIP712(_name, _version) { }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function unequip(uint256 tokenId) public override {
    require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
    _usedHashes.unset(tokenId);
    _burn(tokenId);
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "balanceOf: address zero is not a valid owner");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function give(
    address to,
    string calldata uri,
    bytes calldata signature
  ) external override returns (uint256) {
    require(msg.sender != to, "give: cannot give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, uri, signature);
    _mint(msg.sender, to, tokenId, uri);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function take(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external override returns (uint256) {
    require(msg.sender != from, "take: cannot take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, uri, signature);
    _mint(from, msg.sender, tokenId, uri);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    string calldata uri,
    bytes calldata signature
  ) internal view returns (uint256) {
    bytes32 hash = _getHash(active, passive, uri);
    uint256 tokenId = uint256(hash);

    require(
      SignatureChecker.isValidSignatureNow(passive, hash, signature),
      "_safeCheckAgreement: invalid signature"
    );
    require(!_usedHashes.get(tokenId), "_safeCheckAgreement: already used");
    return tokenId;
  }

  function _getHash(
    address active,
    address passive,
    string calldata uri
  ) internal view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(
        AGREEMENT_HASH,
        active,
        passive,
        keccak256(bytes(uri))
      )
    );
    return _hashTypedDataV4(structHash);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _mint(
    address from,
    address to,
    uint256 tokenId,
    string memory uri
  ) internal returns (uint256) {
    require(!_exists(tokenId), "mint: tokenID exists");
    _balances[to] += 1;
    _owners[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    emit Transfer(from, to, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal {
    address owner = ownerOf(tokenId);
    _balances[owner] -= 1;
    delete _owners[tokenId];
    delete _tokenURIs[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }
}
