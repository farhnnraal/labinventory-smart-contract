// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract LabInventory {
    struct Tool {
        bytes32 toolName;           // Used 32 bytes space, support 32 characters
        address borrowedBy;         // Used 20 bytes space
        bytes6 toolCode;            // Used 6 bytes space, support 6 characters
        uint40 borrowedAt;          // Used 5 bytes space
        bool isAvailable;           // Used 1 bytes space         
    }

    // State Variables & Mapping
    address public labAdmin;
    mapping(bytes6 => Tool) public tools;
    mapping(address => bool) public approvedBorrowers;

    // Event
    event ToolAdded(bytes32 toolName, bytes6 indexed toolCode);
    event BorrowerApproved(address indexed borrower);
    event BorrowedTool(bytes6 indexed toolCode, address indexed borrower, uint40 timestamp);
    event ReturnedTool(bytes6 indexed toolCode, address indexed borrower, uint40 timestamp);

    // Regulations by Modifiers
    
    modifier onlyAdmin() {
        require(msg.sender == labAdmin, "Only admin can do this");
        _;
    }

    modifier onlyApproved() {
        require(approvedBorrowers[msg.sender], "You're not an approved lab member");
        _;
    }

    modifier toolExists(bytes6 _toolCode) {
        require(tools[_toolCode].toolCode != 0, "Tool code is already exists");
        _;
    }
    
    constructor() {
        labAdmin = msg.sender;
    }

    // OnlyAdmin function

    function approvingBorrower(address _student) external onlyAdmin {
       approvedBorrowers[_student] = true;
       emit BorrowerApproved(_student);
    }

    function addingTool(bytes32 _toolName, bytes6 _toolCode) external onlyAdmin toolExists(_toolCode) {
        tools[_toolCode] = Tool({
            toolName: _toolName,
            borrowedBy: address(0),
            toolCode: _toolCode,
            borrowedAt: 0,
            isAvailable: true
        });

        emit ToolAdded(_toolName, _toolCode);
    }

    // General function

    function borrowingTool(bytes6 _toolCode) external onlyApproved toolExists(_toolCode) {
        Tool storage tool = tools[_toolCode];
        require(tool.isAvailable, "Tool is currently borrowed");

        tool.borrowedBy = msg.sender;
        tool.borrowedAt = uint40(block.timestamp);
        tool.isAvailable = false;

        emit BorrowedTool(_toolCode, msg.sender, tool.borrowedAt);
    }

    function returningTool(bytes6 _toolCode) external onlyApproved toolExists(_toolCode) {
        Tool storage tool = tools[_toolCode];
        require(!tool.isAvailable, "Tool is available");
        require(
            msg.sender == tool.borrowedBy || msg.sender == labAdmin,
            "You're not the student who borrowed this tool"
        );

        address previousBorrower = tool.borrowedBy;

        tool.borrowedBy = address(0);
        tool.borrowedAt = 0;
        tool.isAvailable = true;

        emit ReturnedTool(_toolCode, previousBorrower, uint40(block.timestamp));
    }
}