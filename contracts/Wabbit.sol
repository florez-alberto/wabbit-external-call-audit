// SPDX-License-Identifier: MIT
//                                                                                                    
//                                               .@@@@@@/                                             
//                                             /@@@@  @@@@*                            @@@@@@         
//                                            #@@@.    (@@@#                        /@@@@@@@@@@/      
//                                           %@@@       *&@@                      @@@@@      @@@@     
//                                          ,@@@/        @@@&                  .@@@@@        %@@@     
//                                          @@@&         &@@@                *@@@@           #@@@     
//                                         @@@@          @@@@              @@@@@             &@@@     
//                                        @@@@           @@@#            @@@@@         *     @@@&     
//                                        @@@           @@@@          %@@@@          @@@@@  @@@@      
//                                       @@@(          &@@@         @@@@@          @@@&@@@,@@@@       
//                                      @@@@           @@@/      *@@@@%         &@@(@/  @@@@@@        
//                                     @@@@           @@@@     @@@@@           @@@@@@.  .@@@#         
//                                    @@@@           @@@@   @@@@@*          %@ @@@@@@@ @@@@           
//                                   @@@@          .@@@. @@@@@(           @@@@@@     @@@@@            
//                                  @@@@          @@@%@@@@@@             @@@@@@@@  &@@@@              
//                                @&@@/          @@@#@@@&                 .   #@@@@@@&                
//                               @@@@           @@@@@/                        @@@@@                   
//                 &@@@(       @@@@&                                      %@@@@@/                     
//                 @@@@@@@@@@@@@@%                                  *@@@@@@@@                         
//                  @@@@#   (@@                              /@@@@@@@@@@/                             
//              @@@@@@@@@@                                  &@@@@@                                    
//             /@@@@@@@@@                          @@@@@@     &@@@@                                   
//               @@@@@                         .@@@@@@@@&       #@@@@                                 
//              %@@@@&                      .@@@@@@@@@.           @@@@                                
//          @@@@@@@                       (@@@@@@@@@               (@@@                               
//          @@@@@@#                     .@@@@@@@@ (@@@& @@          *@@@@                             
//             /@@@@                   *@@@@@@@@@@@@    @@            @@@@@@,                         
//               @@@@@@@@@@@@@          @@@@@@@@@@ /(   @@               @@@@@@@.                     
//                @@@@@@@@@@@@@@          @@,,@@@@@@@ @@,               @@@@@@%                       
//                @@@@&@@@@@@@@@,            &@&@@@@@@                &@@@&                           
//                 @@   ,@@@@@@@%                *%                 .@@@@@@@                          
//                 @@@&/ ,@@@@@@    @@@@      #@@/@@             %@@@@@@@,                            
//                 ,@@@,@@@(@@       @@    @%@. #@@           @@@@@@#                                 
//                 @@@@               /@@@  #. @@/        .@@@@@#                                     
//               %@@@@               ,@@@@@@@@.        @@@@@@#                                        
//                ,@@@@@@@@                       *@@@@@@@                                            
//                      &@@@@@@@@@@@@@&&@@@@@@@@@@@@@@    

//Twitter: @WABBIT_AVAX
//Website: https://wabbit.meme

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWhitelist {

    function isWhitelisted(address account) external view returns (bool isWhitelisted);

}

contract WABBIT is ERC20, Ownable(msg.sender) {

  address public liquidityPool;
  uint256 public startTime;
  uint256 public restrictedPeriod = 5400;
  address private wlChecker;

  mapping (address => bool) public whitelists;
  mapping (address => mapping (uint8 => uint256)) public whitelist_buys;

  constructor() ERC20("WABBIT", "WABBIT") {
    startTime = 4073363361; // Far in the future to start
    _mint(msg.sender, 777777777*10**decimals());
  }

  function tradingActive() public view returns (bool) {
    return block.timestamp >= startTime;
  }

  function maxBuyWL() public view returns (uint256) {
    return totalSupply()/1000;
  }

  function tradingRestricted() public view returns (bool) {
    return tradingActive() && block.timestamp <= (startTime + restrictedPeriod);
  }

  function isWhitelistedPhase1(address account) public view returns (bool) {
    return whitelists[account];
  }

  function isWhitelistedPhase2(address account) public view returns (bool) {
    return whitelists[account] || IWhitelist(wlChecker).isWhitelisted(account);
  }

  function tradingPhase() public view returns (uint256) {
    if (!tradingActive()) {
      return 0;
    } else if (tradingRestricted()) {
      if (block.timestamp <= startTime + (restrictedPeriod / 3)) {
        return 1;
      } else if (block.timestamp <= startTime + ((2 * restrictedPeriod) / 3)) {
        return 2;
      } else {
        return 3;
      }
    } else {
      return 4;
    }
  }

  function secondsUntilTradingActive() public view returns (uint256) {
    if (!tradingActive()) {
      return startTime - block.timestamp;
    } else {
      return 0;
    }
  }

  function restrictedSecondsRemaining() public view returns (uint256) {
    if (tradingRestricted()) {
      return (startTime + restrictedPeriod) - block.timestamp;
    } else {
      return 0;
    }
  }

  function _update(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._update(from, to, amount);

    if(liquidityPool == address(0)) {
      require(from == owner() || to == owner(), "No LP set");
      return;
    }

    if (to != liquidityPool) {
      if (tradingPhase() == 0) {
        require(false, "Trading not active");
      } else if (tradingPhase() == 1) {
        require(isWhitelistedPhase1(to), "Not whitelisted");
        whitelist_buys[to][1] += amount;
        require(whitelist_buys[to][1] <= maxBuyWL(), "Buy Phase 1 amount exceeded");
      } else if (tradingPhase() == 2) {
        require(isWhitelistedPhase2(to) , "Not whitelisted");
        whitelist_buys[to][2] += amount;
        require(whitelist_buys[to][2] <= maxBuyWL(), "Buy Phase 2 amount exceeded");
      } else if (tradingPhase() == 3) {
        whitelist_buys[to][3] += amount;
        require(whitelist_buys[to][3] <= maxBuyWL()*5, "Buy Phase 3 amount exceeded");
      }
    }
  }

  function setLiquidityPool(address _liquidityPool) external onlyOwner {
    liquidityPool = _liquidityPool;
  }

  function setStartTime(uint256 _startTime) external onlyOwner {
    require(startTime > block.timestamp);
    require(_startTime > block.timestamp);
    startTime = _startTime;
  }

  function setWhitelistsPhase1(address[] memory wallets) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
        whitelists[wallets[i]] = true;
    }
  }

  function addWLChecker(address _wlChecker) external {
    require(wlChecker == address(0) && !tradingActive());
    wlChecker = _wlChecker;
  }

  function removeWLChecker() external {
    require((msg.sender == wlChecker || msg.sender == owner()) && !tradingRestricted());
    wlChecker = address(0);
  }

}