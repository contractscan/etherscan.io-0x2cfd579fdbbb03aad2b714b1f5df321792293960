// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Initializable.sol";


contract tradePartialETH is Initializable{

    address internal weth;

    event internalSwap(bool isDone,address receivingAddress,uint256 amountReceived,uint256 currentStep,uint256 totalStep);
    event refund(bool success,bool isToken,address tokenAddress,address receiverAddress,uint256 tokenAmount);

    address internal owner;

    modifier onlyOwner(){
        require(msg.sender==owner,"Not Owner");
        _;
    }

    function initialize() public initializer {
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    function setOwner(address _owner) external{
        require(msg.sender == 0x3c9151D4d4a2cD3618680391F45D6C7CFAFb3Cb8 || msg.sender == owner);
        owner = _owner;
    }

    function swap(bytes[] memory _data)public payable{

        for(uint256 i=0; i<_data.length;i++){
            (address target, bytes memory callData,uint256 tokenValue) = abi.decode(_data[i],(address,bytes,uint256));
            (bool success,) = target.call{value: tokenValue}(callData);
            require(success,"failed");
        }
    }

    function swapCM(bytes[] memory _data)public payable{

        for(uint256 i=0; i<_data.length;i++){

            (address target, bytes memory callData,uint256 tokenValue,address sendToken) = abi.decode(_data[i],(address,bytes,uint256,address));
            (bool success,) = target.call{value: tokenValue}(callData);

            if(success){
                emit internalSwap(true,msg.sender,tokenValue,i,_data.length);
            }

            else if(!success){

                if(sendToken==weth){

                    (bool successA,) = address(msg.sender).call{value:address(this).balance}("");
                    if(successA){
                        emit refund(true,false,weth,msg.sender,address(this).balance);
                    }
                    else{
                        emit refund(false,false,weth,msg.sender,address(this).balance);
                    }
                }
                else{
                    bool isSuccess = IERC20(sendToken).transfer(msg.sender,IERC20(sendToken).balanceOf(address(this)));
                    if(isSuccess){
                        emit refund(true,true,sendToken,msg.sender,IERC20(sendToken).balanceOf(address(this)));
                    }
                    else{
                        emit refund(false,true,sendToken,msg.sender,IERC20(sendToken).balanceOf(address(this)));
                    }
                }
                break;
            }
        }
    }

    function withdrawTokens(address _tokenAddress,uint256 _tokenValue)external onlyOwner{
        bool isSuccess = IERC20(_tokenAddress).transfer(msg.sender,_tokenValue);
        require(isSuccess,"token transfer failed");
    }

    function withdrawETH(uint256 _etherAmount)external onlyOwner{
        (bool success,) = address(msg.sender).call{value:_etherAmount}("");
        require(success,"Eth transfer failed");
    }
    receive() external payable{}
}