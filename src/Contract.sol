// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {NounsToken} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsToken.sol';
import {NounsDescriptorV2} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsDescriptorV2.sol';
import {ERC721, ERC721TokenReceiver} from 'solmate/tokens/ERC721.sol';

enum NounPart {body, accessory, head, glasses}

struct PartInfo {
    NounPart part;
    uint248 nounId;
}

contract NounFour is ERC721("NounFour", "N4"), ERC721TokenReceiver {
    NounsToken immutable nouns;
    NounsDescriptorV2 immutable public descriptors;
    // tokenId => partInfo
    mapping(uint256 => PartInfo) public partInfo;
    uint256 _nonce;

    constructor(NounsToken _nouns, NounsDescriptorV2 _descriptors) {
        nouns = _nouns;
        descriptors = _descriptors;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {

    }

    function withdrawNoun(
        address to,
        uint256 nounId,
        uint256 body, 
        uint256 accessory, 
        uint256 head, 
        uint256 glasses
    ) external {
        _burnPart(body, nounId, NounPart.body);
        _burnPart(body, nounId, NounPart.accessory);
        _burnPart(body, nounId, NounPart.head);
        _burnPart(body, nounId, NounPart.glasses);
        nouns.safeTransferFrom(address(this), to, nounId);
    }

    error NounsOnly();

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (msg.sender != address(nouns)){
            revert NounsOnly();
        }
        
        _mintNounParts(from, tokenId);

        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function _mintNounParts(address to, uint256 nounId) internal {
        uint256 cur = _nonce;
        _mintPart(to, nounId, cur++, NounPart.body);
        _mintPart(to, nounId, cur++, NounPart.accessory);
        _mintPart(to, nounId, cur++, NounPart.head);
        _mintPart(to, nounId, cur++, NounPart.glasses);
    }

    function _mintPart(address to, uint256 nounId, uint256 tokenId, NounPart part) internal {
        _safeMint(to, tokenId);
        partInfo[nounId] = PartInfo({
            part: part,
            nounId: uint248(nounId)
        });
    }

    error MustBeOwnerOrApproved();
    error PartDoesNotMatch();
    error NounIdDoesNotMatch();

    function _burnPart(uint256 id, uint256 nounId, NounPart part) internal {
        if (msg.sender != ownerOf(id) && msg.sender != getApproved[id]) {
            revert MustBeOwnerOrApproved();
        }

        PartInfo storage partInfo = partInfo[id];
        if (part != partInfo.part) {
            revert PartDoesNotMatch();
        }

        if (nounId != partInfo.nounId) {
            revert NounIdDoesNotMatch();
        }

        _burn(id);    
    }
}
