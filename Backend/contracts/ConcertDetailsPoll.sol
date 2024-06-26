// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ticket.sol";

/**
 * @title A contract for managing polls related to concert details
 **/
contract ConcertDetailsPoll {
    struct PollOption {
        uint256 optionId;
        string optionText;
        uint256 votes;
    }

    struct Poll {
        uint256 pollId;
        uint256 concertId;
        string question;
        mapping(uint256 => uint256) ticketVotes;
        mapping(uint256 => bool) ticketHasVoted;
        PollOption[] options;
        uint256 totalVotes;
        bool isOpen;
    }

    mapping(uint256 => Poll) public polls;
    uint256 public pollCounter;
    Ticket public ticketContract;

    event PollCreated(
        uint256 indexed pollId,
        uint256 indexed concertId,
        string question
    );
    event Voted(
        uint256 indexed pollId,
        uint256 indexed ticketId,
        uint256 optionId
    );
    event PollClosed(uint256 indexed pollId);
    event VoteRetracted(uint256 indexed pollId, uint256 indexed ticketId);

    /**
     * @notice Initializes the contract with the ticket contract's address
     * @param _ticketContract Address of the ticket contract used for validating ticket states
     **/
    constructor(address _ticketContract) {
        ticketContract = Ticket(_ticketContract);
    }

    modifier isActiveTicketAndOpenPoll(uint256 _ticketId, uint256 _pollId) {
        require(
            ticketContract.getTicketState(_ticketId) ==
                Ticket.TicketState.Active,
            "Only active ticket holders can vote"
        );
        require(polls[_pollId].isOpen, "Poll is closed");
        _;
    }

    modifier isValidPoll(uint256 _pollId) {
        require(_pollId < pollCounter, "Poll ID is not valid");
        _;
    }

    /**
     * @notice Creates a new poll related to a concert with multiple options
     * @param _concertId The ID of the concert
     * @param _question The question to be answered in the poll
     * @param _options Array of option texts for the poll
     **/
    function createPoll(
        uint256 _concertId,
        string memory _question,
        string[] memory _options
    ) public {
        polls[pollCounter].pollId = pollCounter;
        polls[pollCounter].concertId = _concertId; // Connect poll to concert
        polls[pollCounter].question = _question;
        for (uint256 i = 0; i < _options.length; i++) {
            polls[pollCounter].options.push(
                PollOption({optionId: i + 1, optionText: _options[i], votes: 0})
            );
        }
        polls[pollCounter].isOpen = true;
        emit PollCreated(pollCounter, _concertId, _question);
        pollCounter++;
    }

    /**
     * @notice Allows ticket holders to vote on an option in an open poll
     * @param _ticketId ID of the ticket used to vote
     * @param _pollId ID of the poll being voted on
     * @param _optionId ID of the option chosen
     **/
    function vote(
        uint256 _ticketId,
        uint256 _pollId,
        uint256 _optionId
    )
        public
        isValidPoll(_pollId)
        isActiveTicketAndOpenPoll(_ticketId, _pollId)
    {
        require(
            _optionId > 0 && _optionId <= polls[_pollId].options.length,
            "Invalid option ID"
        );
        require(
            polls[_pollId].concertId == ticketContract.getConcertId(_ticketId),
            "Ticket should be of same Concert"
        );

        polls[_pollId].ticketVotes[_ticketId] = _optionId;
        polls[_pollId].options[_optionId - 1].votes++;
        polls[_pollId].totalVotes++;
        emit Voted(_pollId, _ticketId, _optionId);
    }

    /**
     * @notice Closes a poll to further voting
     * @param _pollId ID of the poll to close
     **/
    function closePoll(uint256 _pollId) public isValidPoll(_pollId) {
        polls[_pollId].isOpen = false;
        emit PollClosed(_pollId);
    }

    /**
     * @notice Retracts a vote previously made by a ticket in an open poll
     * @param _ticketId ID of the ticket retracting the vote
     * @param _pollId ID of the poll from which to retract the vote
     **/
    function retractVote(
        uint256 _ticketId,
        uint256 _pollId
    )
        public
        isValidPoll(_pollId)
        isActiveTicketAndOpenPoll(_ticketId, _pollId)
    {
        require(
            polls[_pollId].ticketVotes[_ticketId] != 0,
            "No vote to retract"
        );

        uint256 optionId = polls[_pollId].ticketVotes[_ticketId];
        polls[_pollId].options[optionId - 1].votes--;
        polls[_pollId].totalVotes--;
        delete polls[_pollId].ticketVotes[_ticketId];
        emit VoteRetracted(_pollId, _ticketId);
    }

    // Getter functions for detailed poll information below

    // Function to get the number of votes for a specific option in a poll
    function getVotesForOption(
        uint256 _pollId,
        uint256 _optionId
    ) public view returns (uint256) {
        require(
            _optionId > 0 && _optionId <= polls[_pollId].options.length,
            "Invalid option ID"
        );
        return polls[_pollId].options[_optionId - 1].votes;
    }

    // Function to check if a poll is open
    function isPollOpen(uint256 _pollId) public view returns (bool) {
        return polls[_pollId].isOpen;
    }

    // Function to retrieve poll details including options
    function getPollDetails(
        uint256 _pollId
    )
        public
        view
        returns (uint256, string memory, string[] memory, uint256[] memory)
    {
        uint256 concertId = polls[_pollId].concertId; // Retrieve concertId
        string memory question = polls[_pollId].question;
        uint256 optionsCount = polls[_pollId].options.length;
        string[] memory optionsText = new string[](optionsCount);
        uint256[] memory votes = new uint256[](optionsCount);

        for (uint256 i = 0; i < optionsCount; i++) {
            optionsText[i] = polls[_pollId].options[i].optionText;
            votes[i] = polls[_pollId].options[i].votes;
        }

        return (concertId, question, optionsText, votes);
    }
}
