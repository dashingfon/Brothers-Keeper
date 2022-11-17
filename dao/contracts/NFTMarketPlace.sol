//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin4.8.0/contracts/access/Ownable.sol";
import "@openzeppelin4.8.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin4.8.0/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin4.8.0/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin4.8.0/contracts/utils/Strings.sol";
import "../interfaces/ITablelandTables.sol";



contract MarketPlace is ERC721Holder, Ownable {

    event Listed (
        address seller,
        uint listingId
        address token,
        uint tokenId,
        uint price
    );

    event Sold (
        address buyer,
        uint listingId
        address token,
        uint tokenId,
        uint price
    );

    event Cancelled (
        address seller,
        uint listingId
        address token,
        uint tokenId
    );

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }
    
    struct Listing {
        ListingStatus status;
        address seller;
        address token;
        uint tokenId;
        uint listingId;
        uint price;
    }

    uint16 immutable _feeNumerator; // divides by 1000 to get the percentage
    ITablelandTables immutable _tableland;
    uint16 constant _feeDenominator = 1000;
    string public _prefix;
    uint private _listingId;
    uint public _tableId;

    mapping (uint => Listing) private _listings;

    constructor (uint8 fee, string prefix, address registry) {
        _feeNumerator = fee;
        _prefix = prefix;
        _tableland = ITablelandTables(registry)
        _tableId = _tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                prefix,
                "_",
                Strings.toString(block.chainid),
                " (listingId integer primary key, seller text, token text, tokenId integer, price integer, status integer);"
            )
        );
    }

    function _run (address caller, uint256 tableId, string memory statement) private {
        _tableland.runSQL(
            caller, tableId, statement);
    }

    function listToken(address token, uint tokenId, uint price) external {
        
        _sendERC721Token(tokenAdd, msg.sender, reciepient, amount);
        Listing memory listing = Listing(
            ListingStatus.Active,
            msg.sender,
            token,
            tokenId,
            _listingId,
            price
        );
        _listings[_listingId] = listing;

        _run(
            address(this),
            _tableId,
            string.concat(

            ));

        _listingId ++;
        emit Listed (msg.sender, listing.listingId, token, tokenId, price)

    }

    function cancelListing(uint listingId) private {
        Listing memory listing = _listings[listingid];

        require(msg.sender != listing.seller,
            "Only seller can cancel listing");
        require(listing.status == ListingStatus.Cancelled, 
            "Listing is not active");

        _sendERC721Token(listing.token,
                         address(this),
                         msg.sender,
                         listing.tokenId);

        _run(
            address(this),
            _tableId,
            string.concat(

            ));

        delete(_listings[listingId]);
        emit Cancelled (listing.seller,
                        listing.listingId,
                        listing.token,
                        listing.tokenId)
    }

    function buyToken(uint listingId) external payable {
        
        Listing memory listing = _listings[listingid];
        require(msg.sender != listing.seller, "seller cannot be Buyer");
        require(listing.status == ListingStatus.Active, 
            "Listing is not Active");
        require(msg.value >= listing.price, "Insufficient Amount");
        _sendERC721Token(listing.token,
                         address(this),
                         msg.sender,
                         listing.tokenId);

        uint feeCollected = _feeNumerator * listing.price / _feeDenominator;
        _sendCoin(listing.seller, listing.price - feeCollected);

        _run(
            address(this),
            _tableId,
            string.concat(

            ));

        delete(_listings[listingId]);
        emit Sold (
            msg.sender,
            listing.listingId
            listing.token,
            listing.tokenId,
            listing.price
        );
    }

    function setTableId(uint tableId) external onlyOwner() {
        _tableId = tableId;
    }

    function setPrefix(string prefix) external onlyOwner() {
        _prefix = prefix;
    }

    function _sendCoin(address payable recipient, uint amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require (success, "Transfer Failed.");
        emit transferSent(address(this), recipient);
    }
    
    function sendCoin(address payable recipient, uint amount) external onlyOwner() {
        require(address(this).balance >= amount, "Insufficient funds");
        _sendCoin(recipient,amount);
    }

    function _sendERC20Token(address tokenAdd, address reciepient, uint amount) private {
        IERC20(tokenAdd).transfer(reciepient, amount);
        emit transferSent(tokenAdd, reciepient);
    }
    function sendERC20Token(
        address tokenAdd, address reciepient,uint amount) external onlyOwner() {
        require(IERC20(tokenAdd).balanceOf(address(this)) >= amount,
            "Insufficient Funds");
        _sendToken(tokenAdd,reciepient,amount);
    }

    function _sendERC721Token(
        address tokenAdd,
        address sender,
        address reciepient,
        uint tokenId) private {

        IERC721(tokenAdd).transferFrom(sender, reciepient, tokenId);
        emit transferSent(tokenAdd, reciepient);
    }
    function sendERC721Token(
        address tokenAdd,
        address sender,
        address reciepient,
        uint tokenId) external onlyOwner() {
            
        require(IERC721(tokenAdd).ownerOf(tokenId) = sender,
            "MarketPlace doesnt own token");
        _sendERC721Token(tokenAdd, sender, reciepient, tokenId);
    }

    receive() external payable {

    }

}
