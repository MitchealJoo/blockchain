// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC165 {
    //ERC165 是一个接口检测标准，用于检查合约是否支持某个接口
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


//ERC721接口定义了NFT的标准，描述了所有NFT必须实现的函数和事件: 包括代币的转移、批准以及查询功能
interface IERC721 is IERC165 {
    //因为区块链上的事件不能被直接读取，使用 indexed 后，这些参数就可以在事件日志中被索引
    //(单个事件里索引的参数最多为 3 个,开发者可以利用 indexed 参数在前端或后端应用中轻松查找与特定参数相关的事件)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); //用于记录NFT从一个地址转移到另一个地址。
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); //用于记录某个地址对NFT的授权。
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); //用于记录全局操作员的设置。


    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}



interface IERC721Receiver {
    //当NFT被安全转移到合约地址时，合约必须实现这个接口。它确认接收合约支持接收NFT。
    //防止代币发送到不能处理它们的合约地址中，从而避免代币丢失
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

}



contract ERC721 is IERC721 {
    //indexed 只能用于事件参数，不能用于状态变量。状态变量存储在合约的存储空间中，而 indexed 是为了日志检索而优化的，二者有不同的作用和场景。

    //保存每个tokenId的所有者地址(tokenId => ownerContract)
    mapping(uint256 => address) private _owners;
    //每个地址持有的NFT数量 (ownerContract => num)
    mapping(address => uint256) private _balances;
    //每个tokenId批准给谁操作(tokenId => operatorContract)
    mapping(uint256 => address) private _tokenApprovals;
    //授权某个操作员管理所有者的所有NFT(ownerContract => (operatorContract=>true/false) )
    //即某个所有者地址是否授权了某个操作员地址管理它的所有NFT
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    //检查合约是否支持ERC165和ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }


    //balanceOf 返回某地址拥有的NFT数量
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }


    //ownerOf 返回特定tokenId的所有者地址
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    //isApprovedForAll 检查操作员是否被授权
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);

    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }


    //approve 授权一个地址操作某个tokenId
    function approve(address to, uint256 tokenId) public virtual override {

        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);

    }

    //getApproved 获取某个tokenId被授权的地址。
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }



    //setApprovalForAll 为操作员授权或撤销其管理所有NFT的权限 (方便授权操作员管理多个NFT)
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));

    }

    //transferFrom 直接转移NFT,节省gas
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);

    }


    //safeTransferFrom 包含检查转移是否安全，避免发送到不能接收NFT的地址。
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }



    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);

    }


    //安全转移NFT，确保接收方支持接收NFT
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");

    }



    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        //确保要转移的NFT确实属于 from 地址，防止非持有者试图转移。
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        //防止将NFT转移到 0x0 空地址，避免NFT“丢失”
        require(to != address(0), "ERC721: transfer to the zero address");

        // 清除对该tokenId的授权，防止旧持有者仍能操作
        _approve(address(0), tokenId);
        // 更新转出地址的NFT余额
        _balances[from] -= 1; 
        // 更新接收地址的NFT余额
        _balances[to] += 1;
        // 更新所有者为新地址
        _owners[tokenId] = to;

        // 触发转移事件 ( 通知链上观察者（如前端应用、区块链浏览器）该NFT所有权发生了变化。)
        emit Transfer(from, to, tokenId);
    }




    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }

    }


    //创建一个新的NFT
    function _mint(address to, uint tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    //销毁一个NFT
    function _burn(uint tokenId) internal {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "ERC721: burn of token that is not own");
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

}



contract MyNFT is ERC721 {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }



    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

}