// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract LabInventory {
    // 1. STATE VARIABLES
    address public labAdmin;
    uint256 public toolCount;

    // 2. DATA STRUCTURE (Blueprint for each lab tool)
    struct Tool {
        uint256 id;
        string name;
        bool isAvailable;
        address currentBorrower;
        uint256 borrowedAt;
    }

    // 3. MAPPINGS (Key-value storage on the blockchain)
    mapping(uint256 => Tool) public tools;
    mapping(address => bool) public approvedBorrowers;

    // 4. EVENTS (Logs emitted to notify your frontend app)
    event ToolAdded(uint256 indexed toolId, string name);
    event BorrowerApproved(address indexed borrower);
    event ToolBorrowed(uint256 indexed toolId, address indexed borrower, uint256 timestamp);
    event ToolReturned(uint256 indexed toolId, address indexed borrower, uint256 timestamp);

    // 5. MODIFIERS (Reusable security checks)
    modifier onlyAdmin() {
        require(msg.sender == labAdmin, "Only lab admin can perform this action");
        _;
    }

    modifier onlyApproved() {
        require(approvedBorrowers[msg.sender], "You are not an approved lab member");
        _;
    }

    // 6. CONSTRUCTOR (Sets the person who deploys the contract as the admin)
    constructor() {
        labAdmin = msg.sender;
        approvedBorrowers[msg.sender] = true; // Admin can also borrow tools
    }

    // --- ADMIN FUNCTIONS ---

    function approveBorrower(address _student) public onlyAdmin {
        approvedBorrowers[_student] = true;
        emit BorrowerApproved(_student);
    }

    function addTool(string memory _name) public onlyAdmin {
        toolCount++;
        tools[toolCount] = Tool({
            id: toolCount,
            name: _name,
            isAvailable: true,
            currentBorrower: address(0),
            borrowedAt: 0
        });

        emit ToolAdded(toolCount, _name);
    }

    // --- BORROWER FUNCTIONS (Free to call, no deposit required) ---

    function borrowTool(uint256 _toolId) public onlyApproved {
        require(_toolId > 0 && _toolId <= toolCount, "Tool does not exist");
        Tool storage tool = tools[_toolId];
        require(tool.isAvailable, "Tool is currently borrowed by someone else");

        tool.isAvailable = false;
        tool.currentBorrower = msg.sender;
        tool.borrowedAt = block.timestamp;

        emit ToolBorrowed(_toolId, msg.sender, block.timestamp);
    }

    function returnTool(uint256 _toolId) public {
        require(_toolId > 0 && _toolId <= toolCount, "Tool does not exist");
        Tool storage tool = tools[_toolId];
        require(!tool.isAvailable, "Tool is not currently borrowed");
        require(
            tool.currentBorrower == msg.sender || msg.sender == labAdmin,
            "Only the borrower or admin can return this tool"
        );

        address previousBorrower = tool.currentBorrower;
        tool.isAvailable = true;
        tool.currentBorrower = address(0);
        tool.borrowedAt = 0;

        emit ToolReturned(_toolId, previousBorrower, block.timestamp);
    }
}