// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {NounsToken} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsToken.sol';
import {NounsDescriptorV2} from 'nouns-monorepo/packages/nouns-contracts/contracts/NounsDescriptorV2.sol';
import {NounsDAOLogicV1} from 'nouns-monorepo/packages/nouns-contracts/contracts/governance/NounsDAOLogicV1.sol';


import {NounFour} from 'src/NounFour.sol';

/// TODO TEST ME!!!!

contract NounFourTest is Test {
    NounsToken nouns = NounsToken(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
    NounFour nounFour = new NounFour(
        nouns,
        NounsDescriptorV2(0x6229c811D04501523C6058bfAAc29c91bb586268),
        NounsDAOLogicV1(0xa43aFE317985726E4e194eb061Af77fbCb43F944)
    );
    function setUp() public {}

    function testExample() public {
        address owner = nouns.ownerOf(1);
        vm.prank(owner);
        nouns.safeTransferFrom(owner, address(nounFour), 1);
        emit log_string('body \n');
        emit log_string(nounFour.tokenURI(0));
        emit log_string('accessory \n');
        emit log_string(nounFour.tokenURI(1));
        emit log_string('head \n');
        emit log_string(nounFour.tokenURI(2));
        emit log_string('glasses \n');
        emit log_string(nounFour.tokenURI(3));
    }
}
