// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract PIGYToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    address public rewardsAddress;
    uint256 public totalRewards;
    mapping(address => uint256) public claimed;
    IERC721 public linkedNFT;
    uint256 public linkedNFTId;

    constructor(
        address _linkedNFT,
        uint256 _linkedNFTId,
        address _rewardsAddress
    ) ERC20("PIGY", "PY") {
        _mint(msg.sender, INITIAL_SUPPLY);
        linkedNFT = IERC721(_linkedNFT);
        linkedNFTId = _linkedNFTId;
        rewardsAddress = _rewardsAddress;
    }

    receive() external payable {
        require(msg.sender == rewardsAddress, "Only rewards address can deposit");
        totalRewards += msg.value;
    }

    fallback() external payable {
        require(msg.sender == rewardsAddress, "Only rewards address can deposit");
        totalRewards += msg.value;
    }

    function claim() external nonReentrant {
        require(balanceOf(msg.sender) > 0, "You must hold tokens");
        uint256 reward = pendingRewards(msg.sender);
        require(reward > 0, "No rewards available");
        claimed[msg.sender] += reward;
        (bool sent, ) = payable(msg.sender).call{value: reward}("");
        require(sent, "Reward transfer failed");
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 userBalance = balanceOf(user);
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        uint256 entitled = (totalRewards * userBalance) / supply;
        return entitled - claimed[user];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateRewardsAddress(address newAddress) external onlyOwner {
        rewardsAddress = newAddress;
    }

    function _update(address from, address to, uint256 amount) internal override whenNotPaused {
        super._update(from, to, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Emergency withdraw failed");
    }
}