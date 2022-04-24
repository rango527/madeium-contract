// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public mintCost = 0.01 ether; // For test
    uint256 public maxSupply = 6666;
    uint256 public mintLimit = 3;

    // uint256 public allowMintDate = 1650326400; // 2022-04-19 00:00:00 GMT+0
    // uint256 public publicMintDate = 1650412800; // 2022-04-20 00:00:00 GMT+0
    uint256 public allowMintDate = 1648821600; // 2022-04-01 00:00:00 GMT+0
    uint256 public publicMintDate = 1649044800; // 2022-04-04 00:00:00 GMT+0
    // Reserve 100 KNOCKED for team - Giveaways/Prizes etc
    uint256 public teamReserve;

    bool public paused = false;

    address public teamWallet;

    mapping(address => bool) private botWallets;
    mapping(address => bool) private allowlistUsers;
    mapping(address => uint256) private mintedNums;

    constructor(
        string memory _initBaseURI,
        address _teamWallet,
        uint256 _teamReserve
    ) ERC721("Knocked", "KK") {
        baseURI = _initBaseURI;
        teamWallet = _teamWallet;
        teamReserve = _teamReserve;
        mintTeamReserve(_teamWallet, _teamReserve);
    }

    function mintTeamReserve(address _teamWallet, uint256 _teamReserve)
        internal
    {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= _teamReserve; i++) {
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

    function addBotWallet(address botwallet) external onlyOwner() {
        botWallets[botwallet] = true;
    }

    function removeBotWallet(address botwallet) external onlyOwner() {
        botWallets[botwallet] = false;
    }

    function getBotWalletStatus(address botwallet) external view returns (bool) {
        return botWallets[botwallet];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint() external payable nonReentrant {
        require(!paused);
        // TODO: check price of allow mint and public mint
        require(mintCost == msg.value, "Invalid price");
        require(limitStatus(msg.sender), "Excess the mint limit");
        require(!botWallets[msg.sender], "bots can't mint");

        uint256 supply = totalSupply();
        require(supply < maxSupply);

        {
            uint256 timeNow = block.timestamp;
            require(timeNow >= allowMintDate, "Mint is not started");
            if (timeNow < publicMintDate) {
                require(isAllowListed(msg.sender), "Not allow list address");
            }
        }

        mintedNums[msg.sender] = mintedNums[msg.sender] + 1;
        _safeMint(msg.sender, supply + 1);
    }

    function limitStatus(address _user) public view returns (bool) {
        if (mintedNums[_user] < mintLimit) {
            return true;
        } else {
            return false;
        }
    }

    function isAllowListed(address _user) public view returns (bool) {
        return allowlistUsers[_user];
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

    function setMintCost(uint256 _newCost) external onlyOwner {
        mintCost = _newCost;
    }

    function setTeamReserve(uint256 _teamReserve) external onlyOwner {
        teamReserve = _teamReserve;
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

    function setTeamAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        teamWallet = _newAddress;
    }

    function setAllowMintDate(uint256 _allowMintDate) external onlyOwner {
        uint256 _publicMintDate = publicMintDate;
        if (_publicMintDate > 0) {
            require(_allowMintDate < _publicMintDate, "should be smaller than publicMintDate");
        }
        allowMintDate = _allowMintDate;
    }

    function setPublicMintDate(uint256 _publicMintDate) external onlyOwner {
        uint256 _allowMintDate = allowMintDate;
        if (_allowMintDate > 0) {
            require(_publicMintDate > _allowMintDate, "should be bigger than allowMintDate");
        }
        publicMintDate = _publicMintDate;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external nonReentrant onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
    }
}
