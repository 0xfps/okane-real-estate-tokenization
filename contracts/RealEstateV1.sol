//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IUSDT {
    function transfer(address, uint256) external;

    function transferFrom(address, address, uint) external;

    function decimals() external view returns (uint8);
}

contract RealEstateV1 is ERC1155URIStorage, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Change this on deployment.
    address public constant TETHER = 0xcd198e12CD9a2Fe20BC81f437b863f61f2D5C2Df;

    string public name;
    string public symbol;
    // uint256 public currentPropertySupply;
    uint256 public constant INITIAL_PROPERTY_PRICE = 50;

    // Put an enum with cancelled, open, sold;

    struct Property {
        string name;
        uint256 totalTokens;
        uint256 tokensSold;
        string country;
        // string addressInfo;
        // string latitude;
        // string longtitude;
        // string area;
        // Put an enum with cancelled, open, sold;
    }

    // Property[] public propertyList;
    mapping(uint256 => Property) public tokenIdToProperty;
    mapping(uint256 => bool) public checkTokenSupplyStatus;
    mapping(uint256 => uint) public totalTokenSupplyForAGivenProperty;
    mapping(uint256 => string) public tokenIdToImageLink;

    constructor() ERC1155("") {
        name = "Wakaru";
        symbol = "WK";
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        if (!checkTokenSupplyStatus[_tokenId]) revert("Wakaru: TOKEN_INEXISTENT");
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "',
            getPropertyName(_tokenId),
            '",',
            '"description": "Fractionalised Real Estate Property by Wakaru Company",',
            '"totalTokens": "',
            getTotalTokens(_tokenId),
            '",',
            '"tokensSold": "',
            getTokensSold(_tokenId),
            '",',
            '"country": "',
            getCountry(_tokenId),
            '",',
            '"image": "',
            tokenIdToImageLink[_tokenId],
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function getTotalTokens(
        uint256 _tokenId
    ) public view returns (uint256) {
        if (!checkTokenSupplyStatus[_tokenId]) revert("Wakaru: TOKEN_INEXISTENT");
        // To be converted to string on the frontend.
        return tokenIdToProperty[_tokenId].totalTokens;
    }

    function getTokensSold(
        uint256 _tokenId
    ) public view returns (uint256) {
        if (!checkTokenSupplyStatus[_tokenId]) revert("Wakaru: TOKEN_INEXISTENT");
        // To be converted to string on the frontend.
        return tokenIdToProperty[_tokenId].tokensSold;
    }

    function getCountry(uint256 _tokenId) public view returns (string memory) {
        if (!checkTokenSupplyStatus[_tokenId]) revert("Wakaru: TOKEN_INEXISTENT");
        return tokenIdToProperty[_tokenId].country;
    }

    function getPropertyName(
        uint256 _tokenId
    ) public view returns (string memory) {
        if (!checkTokenSupplyStatus[_tokenId]) revert("Wakaru: TOKEN_INEXISTENT");
        string memory propertyName = tokenIdToProperty[_tokenId].name;
        return propertyName;
    }

    function addAPropertyToSell(
        string memory _name,
        uint256 _totalTokens,
        string memory country,
        string memory image_link
    ) public onlyOwner {
        _tokenIds.increment();

        uint256 currentTokenId = _tokenIds.current();
        checkTokenSupplyStatus[currentTokenId] = true;

        Property memory currentProperty = Property(
            _name,
            _totalTokens,
            0,
            country
        );
        tokenIdToProperty[currentTokenId] = currentProperty;

        tokenIdToImageLink[currentTokenId] = image_link;
        _setURI(currentTokenId, getTokenURI(currentTokenId));
    }

    function updatePropertyStatus(
        uint256 _propertyId,
        bool _newStatus
    ) public onlyOwner {
        if (!checkTokenSupplyStatus[_propertyId]) revert("Wakaru: TOKEN_INEXISTENT");
        checkTokenSupplyStatus[_propertyId] = _newStatus;
    }

    function mint(uint256 _amount, uint256 _propertyId) public {
        require(
            checkTokenSupplyStatus[_propertyId],
            "The property you would like to buy is not available in this time!"
        );

        Property storage currentProperty = tokenIdToProperty[_propertyId];

        require(
            currentProperty.totalTokens >=
            (currentProperty.tokensSold.add(_amount)),
            "There are no available tokens left for selected amount!"
        );

        currentProperty.tokensSold += _amount;

        IUSDT tether = IUSDT(TETHER); // Mega Token Currently

        uint256 decimal = tether.decimals();

        tether.transferFrom(
            msg.sender,
            address(this),
            _amount.mul(INITIAL_PROPERTY_PRICE).mul(10 ** decimal)
        );

        _mint(msg.sender, _propertyId, _amount, "");

        // How will we add a defense mechanism over here?

        // require(propertyTokenPrice.mul(_amount) <= msg.value, "Not enough USDT supplied!");
    }

    // Implement a withdraw for USDT

    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        if (!sent) revert("Wakaru: ETH_NOT_SENT");
    }

    // Function to withdraw ERC20 tokens to the owner's account
    function withdrawERC20(
        uint256 amount,
        address _tokenAddress
    ) external onlyOwner {
        require(amount != 0, "Withdrawal amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);

        bool sent = token.transfer(owner(), amount);
        if (!sent) revert("Wakaru: TOKEN_NOT_SENT");
    }

    // Function to withdraw USDT _tokenAddress will be USDT address on the mainnet, check polygon USDT as well THO
    function withdrawUSDT(uint256 amount) external onlyOwner {
        require(amount != 0, "Withdrawal amount must be greater than zero");

        IUSDT usdt = IUSDT(TETHER);

        // Transfer tokens from the contract to the owner
        usdt.transfer(owner(), amount);
    }
}
