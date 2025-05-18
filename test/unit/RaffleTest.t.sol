// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console, console2} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract RaffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLine;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    address public PLAYER2 = makeAddr("player2");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLine = config.gasLine;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.deal(PLAYER2, STARTING_PLAYER_BALANCE);
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              ENTERRAFFLE
    //////////////////////////////////////////////////////////////*/

    function testRaffleInitializesOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    // if external/public getter function getPlayer exists
    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        address playerRecord = raffle.getPlayer(0);
        // Assert
        assert(playerRecord == PLAYER);
    }

    /**
     * @dev Let's assume there is no getter function getPlayer
     * in this case we should use vm.load(address account,bytes32 slot) returns (bytes32)
     */
    function testRaffleRecordsPlayersWhenTheyEnterNoGetter() public skipFork {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();

        // Calculate the storage slot for s_players[0]
        bytes32 arraySlot = bytes32(uint256(3));
        // s_players is at slot 3 because:
        // slot 0: s_owner (from ConfirmedOwnerWithProposal)
        // slot 1: s_pendingOwner (from ConfirmedOwnerWithProposal)
        // slot 2: s_vrfCoordinator (from VRFConsumerBaseV2Plus)
        // slot 3: s_players (from Raffle)
        console.log("Array slot:", uint256(arraySlot));

        // First read the array length from slot 3
        bytes32 lengthSlot = arraySlot;
        uint256 length = uint256(vm.load(address(raffle), lengthSlot));
        console.log("Array length:", length);

        // For the general case to read array element
        // bytes32 valueSlot = bytes32(
        //    uint256(keccak256(abi.encode(arraySlot))) + 0
        //);

        // For index 0 case to read array element
        bytes32 valueSlot = keccak256(abi.encode(arraySlot));

        console.log("Value slot:", uint256(valueSlot));
        bytes32 value = vm.load(address(raffle), valueSlot);
        console.log("Raw value:", uint256(value));

        // Convert bytes32 to address
        address playerRecord = address(uint160(uint256(value)));
        console.log("Player from storage:", playerRecord);

        // Now you can assert this
        assert(playerRecord == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // move block time forward
        vm.roll(block.number + 1); // increase block number (optional, but is considered a good practice)
        raffle.performUpkeep("");
        // Act
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // Assert
    }

    function testSelectorExample() public pure {
        // Get the full keccak256 hash
        bytes32 fullHash = keccak256("Raffle__RaffleNotOpen()");

        // Get the selector (first 4 bytes)
        bytes4 selector = bytes4(fullHash);

        // This should be equal to the .selector property
        assert(selector == Raffle.Raffle__RaffleNotOpen.selector);
    }

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/

    modifier raffleEntered() {
        /**
         * Since this part is going to be repeatedly used, it is considered
         * a good practice to use a modifier.
         */

        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // move block time forward
        vm.roll(block.number + 1); // increase block number (optional, but is considered a good practice)
        _;
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1); // move block time forward
        vm.roll(block.number + 1); // increase block number (optional, but is considered a good practice)
        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public raffleEntered {
        // Arrange
        // modifier raffleEntered
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public raffleEntered {
        // Arrange
        // modifier raffleEntered

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered {
        // Arrange - modifier raffleEntered

        // Act / Assert
        /**
         *  We can just call raffle.performUpkeep("");
         *  Or use the proper way with address(raffle).call();
         */
        (bool success,) = address(raffle).call(abi.encodeWithSignature("performUpkeep(bytes)", "0x0"));

        assert(success);
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // Arrange - modifier "raffleEntered"

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        raffleEntered
        skipFork
    {
        //Arrange /Act /Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
        //console.log(randomRequestId);
    }

    function testFullfillRandomWordsPickAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
        // Arange
        uint256 additionalEntrants = 3; // 4 total
        uint256 startingIndex = 1;
        address expectedWinnder = address(1); //what it fore

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address newPlayer = address(uint160(i)); //converts any number to an address
            /**
             * This is another cheatcode that does:
             * vm.prank(newPlayer);
             * vm.deal(newPlayer, 1 ether);
             */
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinnder.balance; //what it fore

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinnder);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTRANCE FEE TESTS
    //////////////////////////////////////////////////////////////*/

    function testEntranceFeeIsSetCorrectly() public view {
        assert(raffle.getEntranceFee() == entranceFee);
    }

    function testMultiplePlayersCanEnterWithExactFee() public {
        // Arrange
        address[] memory players = new address[](3);
        players[0] = makeAddr("player1");
        players[1] = makeAddr("player2");
        players[2] = makeAddr("player3");

        // Act
        for (uint256 i = 0; i < players.length; i++) {
            vm.prank(players[i]);
            vm.deal(players[i], entranceFee);
            raffle.enterRaffle{value: entranceFee}();
        }

        // Assert
        assert(raffle.getPlayer(0) == players[0]);
        assert(raffle.getPlayer(1) == players[1]);
        assert(raffle.getPlayer(2) == players[2]);
    }

    /*//////////////////////////////////////////////////////////////
                              STATE MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testRaffleStateTransitionsCorrectly() public raffleEntered {
        // Arrange - modifier raffleEntered
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);

        // Act
        raffle.performUpkeep("");
        
        // Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function testLastTimestampIsUpdatedAfterRaffle() public raffleEntered skipFork {
        // Arrange
        uint256 initialTimestamp = raffle.getLastTimeStamp();
        
        // Act
        raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));
        
        // Assert
        assert(raffle.getLastTimeStamp() > initialTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              WINNER SELECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testWinnerReceivesCorrectAmount() public raffleEntered skipFork {
        // Arrange
        uint256 initialBalance = PLAYER.balance;
        
        // Act
        raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));
        
        // Assert
        assert(PLAYER.balance > initialBalance);
        assert(address(raffle).balance == 0);
    }

    function testWinnerIsRecordedCorrectly() public raffleEntered skipFork {
        // Act
        raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));
        
        // Assert
        assert(raffle.getRecentWinner() == PLAYER);
    }

    /*//////////////////////////////////////////////////////////////
                              EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function testContractHandlesMultipleRounds() public skipFork {
        // First round
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));
        
        // Second round
        vm.prank(PLAYER2);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(2, address(raffle));
        
        // Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() == PLAYER2);
    }
}
