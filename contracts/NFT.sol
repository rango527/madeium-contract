// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // APE / ETH mainnet
    // AggregatorV3Interface public constant priceFeed = AggregatorV3Interface(0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18);
    // For test : DAI / ETC rinkeby testnet
    AggregatorV3Interface public constant priceFeed =
        AggregatorV3Interface(0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D);

    // IERC20 public APEToken = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381); // APE token mainnet
    IERC20 public APEToken = IERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735); // DAI stablecoin rinkeby testnet

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public mintCost = 0.25 ether; // For test
    uint256 public maxSupply = 6666;
    uint256 public mintLimit = 3;

    uint256 public allowMintDate; // 2022-04-01 00:00:00 GMT+0
    uint256 public publicMintDate; // 2022-04-04 00:00:00 GMT+0

    bool public paused = false;
    bool public revealed = false;

    mapping(address => bool) public allowlistUsers;
    mapping(address => bool) public botWallets;
    mapping(address => uint256) public mintedNums;

    event Mint(
        address indexed minter,
        bool isETH,
        uint256 indexed tokenId,
        uint256 mintDate
    );

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address _teamWallet,
        uint256 _teamReserve,
        uint256 _allowMintDate,
        uint256 _publicMintDate
    ) ERC721("Knocked", "KK") {
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
        allowMintDate = _allowMintDate;
        publicMintDate = _publicMintDate;
        mintTeamReserve(_teamWallet, _teamReserve);
    }

    function mint(address _minter) private returns (uint256) {
        require(!paused);
        require(mintedNums[_minter] < mintLimit, "Excess the mint limit");
        require(!botWallets[_minter], "bots can't mint");
        require(block.timestamp >= allowMintDate, "Mint is not started");
        require(_minter.code.length == 0, "Can't from contract");

        uint256 supply = totalSupply();
        require(supply < maxSupply, "Maximum supply excessed");

        if (block.timestamp < publicMintDate) {
            require(allowlistUsers[_minter], "Not allow list address");
        }

        mintedNums[_minter] = mintedNums[_minter] + 1;
        _mint(_minter, supply);

        return supply; 
    }

    function mintWithETH() external payable {
        // TODO: check price of allow mint and public mint
        require(mintCost == msg.value, "Invalid price");
        uint256 tokenId = mint(msg.sender);

        emit Mint(msg.sender, true, tokenId, block.timestamp);
    }

    function mintWithAPE(uint256 _amount) external {
        require(_amount >= getAPEAmount(), "Invalid APE amount");
        APEToken.transferFrom(msg.sender, address(this), _amount);
        uint256 tokenId = mint(msg.sender);

        emit Mint(msg.sender, false, tokenId, block.timestamp);
    }

    function getAPEAmount() public view returns (uint256) {
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        return (mintCost / uint256(price)) * 10 ** 18;
    }

    function limitStatus(address _user) external view returns (bool) {
        return mintedNums[_user] < mintLimit;
    }

    function walletOfOwner(address _owner)
        external
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

    //only owner
    function reveal() external onlyOwner {
        revealed = true;
    }

    function mintTeamReserve(address _teamWallet, uint256 _teamReserve)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(maxSupply > supply);
        for (uint256 i = 0; i < _teamReserve; i++) {
            _mint(_teamWallet, supply + i);
        }
    }

    function addAllowlistUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            allowlistUsers[_users[i]] = true;
        }
    }

    function removeAllowlistUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            allowlistUsers[_users[i]] = false;
        }
    }

    function addBotWallet(address[] memory _botwallet) external onlyOwner {
        for (uint256 i = 0; i < _botwallet.length; i++) {
            botWallets[_botwallet[i]] = true;
        }
    }

    function removeBotWallet(address[] memory _botwallet) external onlyOwner {
        for (uint256 i = 0; i < _botwallet.length; i++) {
            botWallets[_botwallet[i]] = false;
        }
    }

    function setMintCost(uint256 _newCost) external onlyOwner {
        mintCost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMintLimit(uint256 _newMintLimit) external onlyOwner {
        mintLimit = _newMintLimit;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMintDate(uint256 _allowMintDate, uint256 _publicMintDate)
        external
        onlyOwner
    {
        require(
            _allowMintDate < _publicMintDate,
            "should be smaller than publicMintDate"
        );
        allowMintDate = _allowMintDate;
        publicMintDate = _publicMintDate;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            !botWallets[from] && !botWallets[to],
            "BotWallet can't transfer"
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            !botWallets[from] && !botWallets[to],
            "BotWallet can't transfer"
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }
}
