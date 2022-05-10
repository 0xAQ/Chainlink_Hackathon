pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract mortgage {

    address payable owner;
    address public contract_addr;
    constructor() {
        owner = payable(msg.sender);
        contract_addr = address(this);

    }

    modifier OnlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    receive() external payable {}

    function getmatic() external OnlyOwner{
        owner.transfer(address(this).balance);
    }


    struct MortgageItem {
    uint256 tokenId;
    address payable nft_owner;
    uint256 price;
    bool repaid;
    uint deadline;
    }

    mapping(uint256 => MortgageItem) private idToMortgageItem;

    event MortgageItemCreated (
    uint256 indexed tokenId,
    address payable nft_owner,
    uint256 price,
    bool repaid,
    uint deadline
    );

    event MortgageRepaid (
    uint256 indexed tokenId,
    address payable nft_owner,
    bool repaid,
    bool deadline
    );

    // function getApproved(IERC721 _nft) external {
    //     _nft.setApprovalForAll(msg.sender, true);
    //     _nft.setApprovalForAll(address(this), true);
    // }
    
    function borrow(IERC721 _nft, uint256 _tokenID, uint256 nft_price) external {
        require(_nft.ownerOf(_tokenID) == payable(msg.sender), "You are not the owner");
        require(nft_price > 0);
        require(address(this).balance >= ((70*nft_price)/100), "no money ppl");
        // _nft.approve(contract_addr, _tokenID);
        _nft.setApprovalForAll(contract_addr, true);
        _nft.transferFrom(msg.sender, contract_addr, _tokenID);
        idToMortgageItem[_tokenID] = MortgageItem(_tokenID, payable(msg.sender), nft_price, false,(block.timestamp + 30 days));
        emit MortgageItemCreated(_tokenID, payable(msg.sender), nft_price, false, block.timestamp + 30 days);
        payable(msg.sender).transfer((70*idToMortgageItem[_tokenID].price)/100);

    }

    function repay(IERC721 _nft, uint _tokenID) external payable {
        require(idToMortgageItem[_tokenID].nft_owner == payable(msg.sender), "not owner");
        if(idToMortgageItem[_tokenID].deadline < block.timestamp){

        require(msg.value == (90*idToMortgageItem[_tokenID].price)/100);
        idToMortgageItem[_tokenID].repaid = true;
        payable(msg.sender).transfer((10*idToMortgageItem[_tokenID].price)/100);
        _nft.transferFrom(contract_addr, payable(msg.sender), _tokenID);
        emit MortgageRepaid(_tokenID, payable(msg.sender), true, true);
        }
        else{
            _nft.transferFrom(address(this), owner, _tokenID);
            idToMortgageItem[_tokenID].nft_owner = owner;
            emit MortgageRepaid(_tokenID, payable(msg.sender), false, false);
        }
    }
    
}