// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract AccessControl{
    //role => account => bool
    mapping (bytes32 =>mapping(address =>bool)) public roles;

    //0x9ebaaef9be0403ebcd5ec4f304d56cd6eb75f288b2508f50244cb5c5c7c48789
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("amdin"));
    //0xcb61ad33d3763aed2bc16c0f57ff251ac638d3d03ab7550adfd3e166c2e7adb6
    bytes32 public constant USER = keccak256(abi.encodePacked("user"));

    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender],"not authorized");
        _;
    }

    constructor() {
        _grantRole(ADMIN,msg.sender);
    }

    function _grantRole(bytes32 _role,address _account)private{
        roles[_role][_account] = true;
        emit RoleGranted(_role,_account);
    }

    function grantRole(bytes32 _role,address _account)external onlyRole(ADMIN){
        _grantRole(_role, _account);
    }

     function revokeRole(bytes32 _role,address _account)external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RoleRevoked(_role,_account);
    }
}