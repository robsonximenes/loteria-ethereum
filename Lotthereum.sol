pragma solidity ^0.4.11;


contract SafeMath {

    function add(uint x, uint y) internal constant returns (uint z) {
        assert((z = x + y) >= x);
    }
 
    function subtract(uint x, uint y) internal constant returns (uint z) {
        assert((z = x - y) <= x);
    }

    function multiply(uint x, uint y) internal constant returns (uint z) {
        z = x * y;
        assert(x == 0 || z / x == y);
        return z;
    }

    function divide(uint x, uint y) internal constant returns (uint z) {
        z = x / y;
        assert(x == ( (y * z) + (x % y) ));
        return z;
    }
    
    function min64(uint64 x, uint64 y) internal constant returns (uint64) {
        return x < y ? x: y;
    }
    
    function max64(uint64 x, uint64 y) internal constant returns (uint64) {
        return x >= y ? x : y;
    }

    function min(uint x, uint y) internal constant returns (uint) {
        return (x <= y) ? x : y;
    }

    function max(uint x, uint y) internal constant returns (uint) {
        return (x >= y) ? x : y;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
    
    function getDivided(uint numerator, uint denominator) internal constant returns(uint quotient, uint remainder) {
        quotient  = numerator / denominator;
        remainder = numerator - denominator * quotient;
    }
    
}


contract Owned {
    address owner;

    modifier onlyowner() {
        if (msg.sender == owner) {
            _;
        }
    }

    function Owned() {
        owner = msg.sender;
    }
}


contract Mortal is Owned {
    
    function kill() {
        if (msg.sender == owner)
            selfdestruct(owner);
    }
}


contract Lotthereum is Mortal, SafeMath {

    Contest[] private contests; // All contests
    mapping (address => uint) private balances;  // balances per address
    uint currentContest = 0;
    uint ticketPrice = 0.01; // ether
    uint accruedPrize = 0;
    uint fee = 0.05;
    
    struct Contest {
        uint id;
        bool open;
        uint prize;
        Ticket[] tickets;
        address[] winners;
        bool paidOut;
    }

    struct Ticket {
        uint id;
        uint8 number;
        uint contest;
        address onwer;
        bool winner;
    }


    function createContest(
        uint pointer,
        uint maxNumberOfBets,
        uint minAmountByBet,
        uint prize
    ) onlyowner returns (uint id) {
        //todo verificar se o contest corrente está ativo ainda...
        id = contests.length;
        contests.length += 1;
        contests[id].id = id;
        contests[id].open = true;
        contests[id].paidOut = false;
    }

    function closeContest(uint gameId) onlyowner returns (bool) {
        contests[gameId].open = false;
        // event closeContest(gameId);
        return true;
    }

    function openContest(uint gameId) onlyowner returns (bool) {
        contests[gameId].open = true;
        // event openContest(gameId);
        return true;
    }


    /**
    * Divide os pagamentos do concurso! Se não tiver vencedor acumula para o próximo
    */
    function payout(uint contestNumber) internal {
        if(!paid){
            address[] winners = contests[contestNumber].winners;
            if (winners.length > 0) {
                uint prize = divide(contests[contestNumber].prize, winners.length);
                for (i = 0; i < winners.length; i++) {
                    balances[winners[i]] = add(balances[winners[i]], prize);
                    // evento ContestWinner(gameId, games[gameId].currentRound, winners[i], prize);
                }
            }else{
                accruedPrize += contests[contestNumber].prize;
            }
            paidOut = true;
        }
    }


    /*
    Comprar 1 bilhete
    */
    function buyTicket(uint8 favoriteNumber) public payable returns (bool) {
        if (!contests[currentContest].open) {
            return false;
        }

        if (msg.value < ticketPrice) {
            return false;
        }
        
        uint numberOfTickets = msg.value / ticketPrice;

        if (games[gameId].rounds[games[gameId].currentRound].bets.length < games[gameId].maxNumberOfBets) {
            uint id = games[gameId].rounds[games[gameId].currentRound].bets.length;
            games[gameId].rounds[games[gameId].currentRound].bets.length += 1;
            games[gameId].rounds[games[gameId].currentRound].bets[id].id = id;
            games[gameId].rounds[games[gameId].currentRound].bets[id].round = games[gameId].rounds[games[gameId].currentRound].id;
            games[gameId].rounds[games[gameId].currentRound].bets[id].bet = bet;
            games[gameId].rounds[games[gameId].currentRound].bets[id].origin = msg.sender;
            games[gameId].rounds[games[gameId].currentRound].bets[id].amount = msg.value;
            BetPlaced(gameId, games[gameId].rounds[games[gameId].currentRound].id, msg.sender, id);
        }

        if (games[gameId].rounds[games[gameId].currentRound].bets.length >= games[gameId].maxNumberOfBets) {
            closeRound(gameId);
        }

        return true;
    }

    function withdraw() public returns (uint) {
        uint amount = getBalance();
        if (amount > 0) {
            balances[msg.sender] = 0;
            msg.sender.transfer(amount);
            return amount;
        }
        return 0;
    }

    function getBalance() constant returns (uint) {
        if ((balances[msg.sender] > 0) && (balances[msg.sender] < this.balance)) {
            return balances[msg.sender];
        }
        return 0;
    }

    function numberOfClosedGames() constant returns(uint numberOfClosedGames) {
        numberOfClosedGames = 0;
        for (uint i = 0; i < games.length; i++) {
            if (games[i].open != true) {
                numberOfClosedGames++;
            }
        }
        return numberOfClosedGames;
    }

    function getGames() constant returns(uint[] memory ids) {
        ids = new uint[](games.length - numberOfClosedGames());
        for (uint i = 0; i < games.length; i++) {
            if (games[i].open == true) {
                ids[i] = games[i].id;
            }
        }
    }

    function getGameCurrentRoundId(uint gameId) constant returns(uint) {
        return games[gameId].currentRound;
    }

    function getGameRoundOpen(uint gameId, uint roundId) constant returns(bool) {
        return games[gameId].rounds[roundId].open;
    }

    function getGameMaxNumberOfBets(uint gameId) constant returns(uint) {
        return games[gameId].maxNumberOfBets;
    }

    function getGameMinAmountByBet(uint gameId) constant returns(uint) {
        return games[gameId].minAmountByBet;
    }

    function getGamePrize(uint gameId) constant returns(uint) {
        return games[gameId].prize;
    }

    function getRoundNumberOfBets(uint gameId, uint roundId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets.length;
    }

    function getRoundBetOrigin(uint gameId, uint roundId, uint betId) constant returns(address) {
        return games[gameId].rounds[roundId].bets[betId].origin;
    }

    function getRoundBetAmount(uint gameId, uint roundId, uint betId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets[betId].amount;
    }

    function getRoundBetNumber(uint gameId, uint roundId, uint betId) constant returns(uint) {
        return games[gameId].rounds[roundId].bets[betId].bet;
    }

    function getRoundNumber(uint gameId, uint roundId) constant returns(uint8) {
        return games[gameId].rounds[roundId].number;
    }

    function getRoundPointer(uint gameId, uint roundId) constant returns(uint) {
        return games[gameId].rounds[roundId].pointer;
    }

    function getPointer(uint gameId) constant returns(uint) {
        return games[gameId].pointer;
    }

    function () payable {
    }
}
