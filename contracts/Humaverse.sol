// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@OpenZeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@OpenZeppelin/contracts/utils/Counters.sol";
import "@Openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


//had to write the ownable contract out cos context declared here has been declared before
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Humaverse is ERC721Enumerable, Ownable, ReentrancyGuard {
    //using Counters for Counters.Counter;
    //Counters.Counter private _tokenIds;

    using SafeMath for uint256;

    string public HV_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public hvPrice;// = 80000000000000000; //0.08 ETH

    uint public constant maxHVPurchase = 10;

    uint256 public constant MAX_HV = 1000;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    string private baseURI;//remember to turn to private

    event BalanceWithdrawn(uint amount);
    event saleStateFlipped(bool saleIsActive);
    event HVNFTsMinted(address to, uint numberOfNFTs);
    event TokenPriceSet(uint256 hvPrice);
    

    constructor() ERC721("HUMAVERSE", "HVNFT") {}

    function setTimeStamp(uint256 saleStart, uint256 daysOfSale)external onlyOwner {
        REVEAL_TIMESTAMP = saleStart + (86400 * daysOfSale);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner returns(string memory){
        HV_PROVENANCE = provenanceHash;
        return HV_PROVENANCE;
    }

    //check the balance of the ether in the contract address
    function ethBalance() public view returns(uint){
        uint balance = address(this).balance;
        return balance;
    }

    // transfer/withdraw the ether sent to the contract address to the admin/senders/owner(my) address
    function withdraw() external onlyOwner payable{
        uint balance = address(this).balance;
        //address payable dogBoy = msg.sender;
        //(dogBoy).transfer(balance);
        Address.sendValue(payable(owner()), balance);
        emit BalanceWithdrawn(balance );
    }

    /*
    * Pause sale if active, make active if paused works like a toggle switch
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        emit saleStateFlipped(saleIsActive);
    }

    function checkSaleState() public view returns(bool) {
        return saleIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner{
        baseURI = uri;
        //_setBaseURI(baseUri);
        //return baseUri;
        //emit BaseUriSet(baseUri);
    }

    function setHvPrice(uint256 amount) external onlyOwner{
        hvPrice = amount;
        emit TokenPriceSet(hvPrice);
    }

    /**function to mint for public sale after presale has ended */
    function mintPublicSale(uint numberOfNFTs) public onlyOwner {  
        require(totalSupply().add(numberOfNFTs) <= MAX_HV, "Purchase would exceed max supply of Humaverses");//if 
        require(numberOfNFTs > 0, "Must mint at least one NFT/Token");
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numberOfNFTs; i++) {
            _safeMint(msg.sender, supply + i);//add one later and test it out
            
        }
    }

    function mintToken(uint numberOfNFTs) external payable nonReentrant{
        require(saleIsActive == true, "Sale has not started");
        require(numberOfNFTs > 0, "Must mint at least one NFT/Token");
        require(numberOfNFTs <= maxHVPurchase, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfNFTs) <= MAX_HV, "Purchase would exceed max supply of Humaverses");//if 
        require(hvPrice.mul(numberOfNFTs) <= msg.value, "Ether value sent is not correct");//multiply number of nfts with price it should be equal to the sent ether
        
        for (uint256 i = 0; i < numberOfNFTs; i++) {
            //_tokenIds.increment();
            //newItemId = _tokenIds.current();
            uint newItemId = totalSupply();
            if (totalSupply() < MAX_HV) {
                _safeMint(msg.sender, (newItemId));
            }
        }

        emit HVNFTsMinted(msg.sender, numberOfNFTs);

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_HV || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    function tokenURI(uint256 _tokenId) override public view returns(string memory) {
        return string(
               abi.encodePacked(
        //                "https://ipfs.moralis.io:2053/ipfs/", HV_PROVENANCE,
                        baseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
            );
    }

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_HV;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_HV;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}