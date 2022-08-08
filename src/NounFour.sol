// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {NounsToken, INounsSeeder} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsToken.sol';
import {NounsDescriptorV2, ISVGRenderer} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsDescriptorV2.sol';
import {NounsDAOLogicV1} from 'nouns-monorepo/packages/nouns-contracts/contracts/governance/NounsDAOLogicV1.sol';
import {NounsDAOStorageV1} from 'nouns-monorepo/packages/nouns-contracts/contracts/governance/NounsDAOInterfaces.sol';
import {ERC721, ERC721TokenReceiver} from 'solmate/tokens/ERC721.sol';
import {Base64} from 'base64/base64.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';

enum NounPart {body, accessory, head, glasses}

struct PartInfo {
    NounPart part;
    uint248 nounId;
}

contract NounFour is ERC721("NounFour", "N4"), ERC721TokenReceiver {
    NounsToken immutable nouns;
    NounsDescriptorV2 immutable public descriptors;
    NounsDAOLogicV1 immutable public nounsDAO; 
    // tokenId => partInfo
    mapping(uint256 => PartInfo) public partInfo;
    // tokenId => proposalId => support
    mapping(uint256 => mapping(uint256 => uint8)) public voteReceipt;
    uint256 _nonce;

    string private constant _SVG_START_TAG = '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
    string private constant _SVG_END_TAG = '</svg>';

    constructor(NounsToken _nouns, NounsDescriptorV2 _descriptors, NounsDAOLogicV1 _nounsDAO) {
        nouns = _nouns;
        descriptors = _descriptors;
        nounsDAO = _nounsDAO;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        (string memory partType, string memory image) = partSVG(id);

        string memory name = string.concat(partType, ' of Noun ', Strings.toString(partInfo[id].nounId));

        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked('{"name":"', name, '", "description":"', '', '", "image": "', 'data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}')
                )
            )
        );
    }

    error OnlyOwner();

    function castVote(uint256 tokenId, uint256 proposalId, uint8 support) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert OnlyOwner();
        }
        /// TODO
    }

    function conveyVote(uint256 nounId, uint256 body, uint256 accessory, uint256 head, uint256 glasses) external {
        /// TODO, convey vote of noun four to the DAO
    }

    function partSVG(uint256 id) public view returns (string memory partType, string memory svg) {
        PartInfo storage info = partInfo[id];
        (uint48 background, uint48 body, uint48 accessory, uint48 head, uint48 glasses) = nouns.seeds(info.nounId);
        
        bytes memory partBytes;
        if (info.part == NounPart.body) {
            partType = "body";
            partBytes = descriptors.art().bodies(body);
        } else if (info.part == NounPart.accessory) {
            partType = "accessory";
            partBytes = descriptors.art().accessories(accessory);
        } else if(info.part == NounPart.head) {
            partType = "head";
            partBytes = descriptors.art().heads(head);
        } else if(info.part == NounPart.glasses) {
            partType = "glasses";
            partBytes = descriptors.art().glasses(glasses);
        }

        ISVGRenderer.Part memory svgPart = ISVGRenderer.Part({ image: partBytes, palette: _getPalette(partBytes) });

        string memory renderedSVGPart = descriptors.renderer().generateSVGPart(svgPart);

        svg = string.concat(
            _SVG_START_TAG,
            '<rect width="100%" height="100%" fill="#', descriptors.art().backgrounds(background), '" />',
            renderedSVGPart,
            _SVG_END_TAG
        );
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
        _nonce = cur;
    }

    function _mintPart(address to, uint256 nounId, uint256 tokenId, NounPart part) internal {
        _safeMint(to, tokenId);
        partInfo[tokenId] = PartInfo({
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

        PartInfo storage info = partInfo[id];
        if (part != info.part) {
            revert PartDoesNotMatch();
        }

        if (nounId != info.nounId) {
            revert NounIdDoesNotMatch();
        }

        _burn(id);    
    }

    function _getPalette(bytes memory part) private view returns (bytes memory) {
        return descriptors.art().palettes(uint8(part[0]));
    }
}
