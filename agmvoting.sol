/**
 * @file ag,voting.sol
 * @author Dome C. <dome@tel.co.th>
 * @date created 4 Apr 2020
 * Based on 
 * @file ballot.sol
 * @author Jackson Ng <jackson@jacksonng.org>
 * @date created 22nd Apr 2019
 * @date last modified 30th Apr 2019
 */

pragma solidity ^0.5.0;

contract Ballot {

    struct vote{
        address voterAddress;
        bool choice;
    }

    struct voter{
        string voterName;
        bool voted;
        uint weight;
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;
    uint public totalWeight = 0;
    address public ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposal;

    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State { Created, Voting, Ended }
	State public state;

	//creates a new ballot contract
	constructor(
        string memory _ballotOfficialName,
        string memory _proposal) public {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        proposal = _proposal;

        state = State.Created;
    }


	modifier condition(bool _condition) {
		require(_condition);
		_;
	}

	modifier onlyOfficial() {
		require(msg.sender ==ballotOfficialAddress);
		_;
	}

	modifier inState(State _state) {
		require(state == _state);
		_;
	}

    event voterAdded(address voter);
    event voteStarted();
    event voteEnded(uint finalResult);
    event voteDone(address voter);
    event proxyAdded(address voter, address proxy);

    //add voter
    function addVoter(address _voterAddress, string memory _voterName)
        public
        inState(State.Created)
        onlyOfficial
    {
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        v.weight = 1;
        voterRegister[_voterAddress] = v;
        totalVoter++;
        emit voterAdded(_voterAddress);
    }

    //declare voting starts now
    function startVote()
        public
        inState(State.Created)
        onlyOfficial
    {
        state = State.Voting;
        emit voteStarted();
    }


    //proxy
    function addProxy(address _proxyAddress)
        public
        inState(State.Created)
        returns (bool found)
    {
        bool result = false;

        if (bytes(voterRegister[_proxyAddress].voterName).length != 0 && bytes(voterRegister[msg.sender].voterName).length != 0 && voterRegister[msg.sender].weight > 0 && msg.sender != _proxyAddress){

            voterRegister[_proxyAddress].weight += voterRegister[msg.sender].weight;
            voterRegister[msg.sender].weight = 0;

            result = true;
        }

        emit proxyAdded(msg.sender, _proxyAddress);
        return result;
    }


    //voters vote by indicating their choice (true/false)
    function doVote(bool _choice)
        public
        inState(State.Voting)
        returns (bool voted)
    {
        bool found = false;

        if (bytes(voterRegister[msg.sender].voterName).length != 0
        && !voterRegister[msg.sender].voted && voterRegister[msg.sender].weight != 0){
            voterRegister[msg.sender].voted = true;
            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            if (_choice){
                countResult += voterRegister[msg.sender].weight;
            }
            votes[totalVote] = v;
            totalVote++;
            totalWeight += voterRegister[msg.sender].weight;
            found = true;
        }
        emit voteDone(msg.sender);
        return found;
    }

    //end votes
    function endVote()
        public
        inState(State.Voting)
        onlyOfficial
    {
        state = State.Ended;
        finalResult = countResult; //move result from private countResult to public finalResult
        emit voteEnded(finalResult);
    }

    //mass
    function addProxies(address[] memory _addresses, address _toAddress)
        public
        inState(State.Created)
        onlyOfficial
        returns (uint numSuccess)
    {
        uint result = 0;

        if (bytes(voterRegister[_toAddress].voterName).length == 0){
            return result;
        }

        for (uint i=0; i<_addresses.length; i++) {
            address fromAddress = _addresses[i];
            if (bytes(voterRegister[fromAddress].voterName).length != 0 && voterRegister[fromAddress].weight > 0 && fromAddress != _toAddress){
                voterRegister[_toAddress].weight += voterRegister[fromAddress].weight;
                voterRegister[fromAddress].weight = 0;
                result++;
            }
        }

        return result;
    }


}


