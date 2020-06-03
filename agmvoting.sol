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
        uint choice;
    }

    struct voter{
        string voterName;
        bool voted;
        uint weight;
        uint choice;
        bool signed;
    }

    uint[3] private countResults = [0, 0, 0];
    uint[3] public numResults = [0, 0, 0];
    uint[3] public finalResults = [0, 0, 0];


    uint public totalVoter = 0;
    uint public totalVote = 0;
    uint public totalWeight = 0;
    uint public totalWeightVoter = 0;
    uint public totalSign = 0;
    uint public totalSignWeight = 0;

    address public ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposal;

    mapping(address => bool) public ballotManager;

    mapping(address => voter) public voterRegister;

    enum State { Created, Voting, Ended }
	State public state;

	//creates a new ballot contract
	constructor(
        string memory _ballotOfficialName,
        string memory _proposal,
        address[] memory _managerAddresses

    )
    public {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        proposal = _proposal;
        state = State.Created;

        ballotManager[msg.sender] = true;
        for (uint i=0; i<_managerAddresses.length; i++) {
            ballotManager[_managerAddresses[i]] = true;
        }
    }


	modifier condition(bool _condition) {
		require(_condition);
		_;
	}

	modifier onlyOfficial() {
		require(ballotManager[msg.sender]);
		_;
	}


	modifier inState(State _state) {
		require(state == _state);
		_;
	}

	modifier notInState(State _state) {
		require(state != _state);
		_;
	}

    event voterAdded(address voter);
    event voteStarted();
    event voteEnded(uint[3] finalResults);
    event voteDone(address voter);
    event signDone(address voter);
    event proxyAdded(address voter, address proxy);

    //add voter
    function addVoter(address _voterAddress, string memory _voterName, uint weight)
        public
        inState(State.Created)
        onlyOfficial
    {

        if(bytes(voterRegister[_voterAddress].voterName).length != 0){
            totalWeightVoter -= voterRegister[_voterAddress].weight;

        }else{
            totalVoter++;
        }

        totalWeightVoter += weight;
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        v.signed = false;
        v.weight = weight;
        v.choice = 99;
        voterRegister[_voterAddress] = v;


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

    function sign()
        public
        inState(State.Voting)
        returns (bool voted)
    {

        bool found = false;
        if (bytes(voterRegister[msg.sender].voterName).length != 0
         && !voterRegister[msg.sender].signed){
             voterRegister[msg.sender].signed = true;
             totalSign++;
             totalSignWeight += voterRegister[msg.sender].weight;
        }
        emit signDone(msg.sender);

        return found;
    }

    //voters vote by indicating their choice (true/false)
    function doVote(uint _choice)
        public
        inState(State.Voting)
        returns (bool voted)
    {

        bool found = false;

        if (bytes(voterRegister[msg.sender].voterName).length != 0
         && voterRegister[msg.sender].weight != 0){

            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;

            if(voterRegister[msg.sender].voted){

                countResults[voterRegister[msg.sender].choice] -= voterRegister[msg.sender].weight;
                numResults[voterRegister[msg.sender].choice]--;
            }else{
                voterRegister[msg.sender].voted = true;
                totalVote++;
                totalWeight += voterRegister[msg.sender].weight;
            }

            voterRegister[msg.sender].choice = _choice;
            countResults[_choice] += voterRegister[msg.sender].weight;
            numResults[_choice]++;



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
        finalResults = countResults;
        emit voteEnded(finalResults);
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