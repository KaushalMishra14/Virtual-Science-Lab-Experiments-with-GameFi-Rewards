// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract VirtualScienceLab {
    // Contract variables
    address public owner;
    uint256 public platformFee;
    uint256 public rewardPerExperiment;
    uint256 public totalTokens;

    struct User {
        bool isRegistered;
        uint256 tokenBalance;
        uint256 completedExperiments;
    }

    struct Experiment {
        string experimentName;
        bool isCompleted;
    }

    mapping(address => User) public users;
    mapping(address => Experiment[]) public userExperiments;

    // Events
    event UserRegistered(address indexed user);
    event ExperimentCompleted(address indexed user, string experimentName, uint256 tokensEarned);
    event TokensRedeemed(address indexed user, uint256 tokensRedeemed);

    constructor(uint256 _platformFee, uint256 _rewardPerExperiment, uint256 _initialTokens) {
        owner = msg.sender;
        platformFee = _platformFee;
        rewardPerExperiment = _rewardPerExperiment;
        totalTokens = _initialTokens;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier isRegistered() {
        require(users[msg.sender].isRegistered, "User is not registered");
        _;
    }

    // Register user
    function registerUser() external payable {
        require(msg.value == platformFee, "Incorrect platform fee");
        require(!users[msg.sender].isRegistered, "User already registered");

        users[msg.sender] = User({
            isRegistered: true,
            tokenBalance: 0,
            completedExperiments: 0
        });

        emit UserRegistered(msg.sender);
    }

    // Add experiment (Owner only)
    function addExperiment(address _user, string memory _experimentName) external onlyOwner {
        require(users[_user].isRegistered, "User is not registered");
        userExperiments[_user].push(Experiment({
            experimentName: _experimentName,
            isCompleted: false
        }));
    }

    // Complete experiment
    function completeExperiment(uint256 _experimentIndex) external isRegistered {
        require(_experimentIndex < userExperiments[msg.sender].length, "Invalid experiment index");
        Experiment storage experiment = userExperiments[msg.sender][_experimentIndex];
        require(!experiment.isCompleted, "Experiment already completed");

        experiment.isCompleted = true;
        users[msg.sender].tokenBalance += rewardPerExperiment;
        users[msg.sender].completedExperiments += 1;
        totalTokens -= rewardPerExperiment;

        emit ExperimentCompleted(msg.sender, experiment.experimentName, rewardPerExperiment);
    }

    // Redeem tokens
    function redeemTokens(uint256 _tokens) external isRegistered {
        require(users[msg.sender].tokenBalance >= _tokens, "Insufficient tokens");
        users[msg.sender].tokenBalance -= _tokens;
        emit TokensRedeemed(msg.sender, _tokens);
    }

    // Get experiments of a user
    function getUserExperiments(address _user) external view returns (Experiment[] memory) {
        return userExperiments[_user];
    }

    // Owner adds more tokens
    function addTokens(uint256 _amount) external onlyOwner {
        totalTokens += _amount;
    }
}
