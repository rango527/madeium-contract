// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public mintCost = 0.01 ether; // For test
    uint256 public maxSupply = 6666;
    uint256 public mintLimit = 3;

    uint256 public allowMintDate; // 2022-04-01 00:00:00 GMT+0
    uint256 public publicMintDate; // 2022-04-04 00:00:00 GMT+0

    bool public paused = false;

    mapping(address => bool) public allowlistUsers;
    mapping(address => bool) public botWallets;
    mapping(address => uint256) public mintedNums;

    event Mint(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 mintDate
    );

    constructor(
        string memory _initBaseURI,
        address _teamWallet,
        uint256 _teamReserve,
        uint256 _allowMintDate,
        uint256 _publicMintDate
    ) ERC721("Knocked", "KK") {
        baseURI = _initBaseURI;
        mintTeamReserve(_teamWallet, _teamReserve);
        allowMintDate = _allowMintDate;
        publicMintDate = _publicMintDate;
    }

    function mintTeamReserve(address _teamWallet, uint256 _teamReserve)
        public onlyOwner
    {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i <= _teamReserve; i++) {
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

    function mint() external payable {
        require(!paused);
        // TODO: check price of allow mint and public mint
        require(mintCost == msg.value, "Invalid price");
        require(mintedNums[msg.sender] < mintLimit, "Excess the mint limit");
        require(!botWallets[msg.sender], "bots can't mint");
        require(block.timestamp >= allowMintDate, "Mint is not started");
        require(msg.sender.code.length == 0, "Can't from contract");

        uint256 supply = totalSupply();
        require(supply < maxSupply, "Maximum supply excessed");

        if (block.timestamp < publicMintDate) {
            require(allowlistUsers[msg.sender], "Not allow list address");
        }

        mintedNums[msg.sender] = mintedNums[msg.sender] + 1;
        _mint(msg.sender, supply);

        emit Mint(msg.sender, supply, block.timestamp);
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

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMintDate(uint256 _allowMintDate, uint256 _publicMintDate) external onlyOwner {
        require(_allowMintDate < _publicMintDate, "should be smaller than publicMintDate");
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
        require(!botWallets[from] && !botWallets[to], "BotWallet can't transfer");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(!botWallets[from] && !botWallets[to], "BotWallet can't transfer");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
}
