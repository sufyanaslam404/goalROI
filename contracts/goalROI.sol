

pragma solidity ^0.7.0;

interface CreateGoalV2 {
    function idToaddress(uint256 id) external view returns (address);

    function nonce() external view returns (uint256);

    function users(address user)
        external
        view
        returns (
            bool isExist,
            uint256 id,
            address referrer,
            uint256 referredUsers,
            uint256 downlinecount,
            uint256 boosterreward,
            uint256 BoosterDepositCount,
            uint256 BoosterCurrentindex,
            uint256 LevelReward,
            uint256 directreward,
            uint256 incentive,
            uint256 boostercheckpoint
        );

    function getdirects(address user) external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
contract CreateGoalV3 {
    address payable public owner;
    address payable public owner1;
    address payable public owner2;
    uint256 public ownertax = 10;
    uint256 public totalinvested;
    uint256 public totalwithdrawn;
    uint256 public nonce = 1;

    CreateGoalV2 public creategoalv2;
uint256[3] public LevelcurrUserID = [0, 0, 0];
    uint256[3] public LevelactiveUserID = [1, 1, 1];
    uint256[3] public LevelUserCount = [0, 0, 0];
    uint256[6]  LevelFee = [
        20 ether,
        40 ether,
        80 ether,
        160 ether,
        320 ether,
        640 ether
    ];
    uint256[3] public paymentsrequired = [64, 2, 2];
    uint256[3] public requiredDirects = [2, 2, 2];
    uint256[3] public giveawayamounts = [500 ether, 1000 ether, 1500 ether];

    uint256 public boostercurrUserID = 0;
    uint256 public boosteractiveUserID = 1;
    uint256 public boosterUserCount = 0;
    uint256 public boosterFee = 10 ether;
    uint256 public boosterpaymentsrequired = 2;
    uint256 public boostergiveawayamounts = 19 ether;
    uint256 public boosterlockduration = 24 hours;
    uint256 public maxBoostParticipations = 3;
    bool initialized = false;

    struct USERDATA {
        bool isExist;
        uint256 id;
        address payable referrer;
        address[] directs;
        uint256 referredUsers;
        uint256 downlinecount;
        uint256 boosterreward;
        uint256 BoosterDepositCount;
        uint256 BoosterCurrentindex;
        uint256 LevelReward;
        uint256 directreward;
        uint256 incentive;
        uint256 boostercheckpoint;
        mapping(uint256 => LEVELDATA) LevelUser;
        mapping(uint256 => BOOSTERDATA) BoosterUser;
        uint256[10] referralrewardsperlevel;
        uint activeBoosts;
        bool BoostEnded;
    }

    struct LEVELDATA {
        bool isExist;
        uint256 id;
        uint256 payment_received;
    }
    struct BOOSTERDATA {
        bool isExist;
        uint256 id;
        uint256 payment_received;
    }

    mapping(address => USERDATA) public users;

    mapping(uint256 => mapping(uint256 => address)) public userList;
    mapping(uint256 => address) public boosterList;
    mapping(uint256 => address) public idToaddress;
    mapping(address => bool[3]) public levelStatus;

    constructor(
        address _owner,
        address _owner1,
        address _owner2,
        address _creategoalv2
    ) {
        owner = payable(_owner);
        owner1 = payable(_owner1);
        owner2 = payable(_owner2);
        creategoalv2 = CreateGoalV2(_creategoalv2);
    }

    receive() external payable {}

    function initialize() external {
        require(msg.sender == owner, "only owner can initialize");
        require(!initialized, "already initialized");
        uint256 _nonce = creategoalv2.nonce();
        for (uint256 i = 0; i < 15 && nonce <= _nonce; i++) {
            address user = creategoalv2.idToaddress(nonce);
            idToaddress[nonce] = user;
            (
                bool isExist,
                uint256 id,
                address referrer,
                uint256 referredUsers,
                uint256 downlinecount,
                uint256 boosterreward,
                uint256 BoosterDepositCount,
                uint256 BoosterCurrentindex,
                uint256 LevelReward,
                uint256 directreward,
                uint256 incentive,
                uint256 boostercheckpoint
            ) = creategoalv2.users(user);
            if (isExist) {
                users[user].isExist = isExist;
                users[user].id = id;
                users[user].referrer = payable(referrer);
                users[user].referredUsers = referredUsers;
                users[user].downlinecount = downlinecount;
                users[user].boosterreward = boosterreward;
                users[user].directreward = directreward;

                if (user != owner) {
                    Level(payable(user), payable(referrer), 0);
                }
                nonce++;
            }
        }
        if (nonce >= _nonce) {
            initialized = true;
        }
    }

    function buy(address payable reff) public payable {
        require(msg.value == 2 * LevelFee[0], " fee is not correct");
        require(reff != address(0), "referrer address payable is not correct");
        require(reff != msg.sender, "you can not refer yourself");
        require(users[reff].isExist, "referrer is not exist");
        require(!users[msg.sender].isExist, "you have already registered");
        users[msg.sender].id = nonce;
        idToaddress[nonce] = (msg.sender);
        users[msg.sender].referrer = reff;
        users[msg.sender].isExist = true;
        totalinvested += LevelFee[0];
        nonce++;
        address payable upline = users[msg.sender].referrer;
        owner1.transfer(1.5 ether);
        owner2.transfer(0.5 ether);
        owner.transfer(1 ether);
        upline.transfer(12 ether);
        users[upline].directs.push(msg.sender);
        users[upline].directreward += 12 ether;

        Level(payable(msg.sender), reff, 0);
    }

    function buybooster() public payable {
        require(!users[msg.sender].BoostEnded, "you can not boost again");
        require(msg.value == boosterFee, " fee is not correct");
        require(users[msg.sender].isExist, "you have not registered");
        require(
            block.timestamp >=
                users[msg.sender].boostercheckpoint + boosterlockduration,
            "you can not buy booster yet "
        );
        totalinvested += boosterFee;
        booster(payable(msg.sender));
    }

    function Level(
        address payable buyer,
        address payable _referrer,
        uint256 index
    ) internal {
        USERDATA storage user = users[buyer];
        LevelcurrUserID[index]++;
        LevelUserCount[index]++;
        address payable activeuser = payable(
            userList[index][LevelactiveUserID[index]]
        );

        user.LevelUser[index] = LEVELDATA({
            isExist: true,
            id: LevelcurrUserID[index],
            payment_received: 0
        });
        userList[index][LevelcurrUserID[index]] = buyer;
        totalinvested += LevelFee[index];
        users[activeuser].LevelUser[index].payment_received += 1;
        users[activeuser].incentive += LevelFee[index];
        if (
            users[activeuser].LevelUser[index].payment_received >=
            paymentsrequired[index]
        ) {
            users[activeuser].LevelUser[index].payment_received = 0;
            levelStatus[activeuser][index] = true;
            uint256 amount = giveawayamounts[index];

            if (
                amount > 0 &&
                users[activeuser].directs.length == requiredDirects[index]
            ) {
                if (address(this).balance < amount && activeuser!=address(0) ) {
                    amount = address(this).balance - 10 ether;
                }
                uint256 tax = (amount * ownertax) / 100;
                uint256 taxedamount = amount - tax;
                owner.transfer(tax);
                activeuser.transfer(taxedamount);
            }

            users[activeuser].LevelReward += amount;
            if (index == 2) {
                for (uint256 i = 0; i < LevelFee.length; i++) {
                    users[activeuser].LevelUser[i] = LEVELDATA({
                        isExist: false,
                        id: 0,
                        payment_received: 0
                    });
                }
                users[activeuser].BoostEnded = true;
            } else {
                Level(activeuser, _referrer, index + 1);
            }
            LevelactiveUserID[index]++;
            LevelUserCount[index]--;
        }
    }

    function booster(address payable buyer) internal {
        USERDATA storage user = users[buyer];
        boostercurrUserID++;
        boosterUserCount++;
        address payable activeuser = payable(boosterList[boosteractiveUserID]);
        uint256 activeuserindex = users[activeuser].BoosterCurrentindex;
        bool eligibility = getBoosterEligibility(buyer);

        require(
            eligibility,
            "You cannot boost because your maximum boost participation limit exceeded!"
        );
        user.activeBoosts++;
        user.BoosterUser[user.BoosterDepositCount] = BOOSTERDATA({
            isExist: true,
            id: boostercurrUserID,
            payment_received: 0
        });

        boosterList[boostercurrUserID] = buyer;
        user.BoosterDepositCount++;
        user.boostercheckpoint = block.timestamp;
        users[activeuser].BoosterUser[activeuserindex].payment_received += 1;
        if (
            users[activeuser].BoosterUser[activeuserindex].payment_received >=
            boosterpaymentsrequired
        ) {
            users[activeuser].BoosterUser[activeuserindex].payment_received = 0;

            activeuser.transfer(boostergiveawayamounts);
            owner.transfer(1 ether);

            users[activeuser].boosterreward += boostergiveawayamounts;
            users[activeuser].activeBoosts--;
            totalwithdrawn += boostergiveawayamounts;
            users[activeuser].BoosterCurrentindex++;
            boosteractiveUserID++;
            boosterUserCount--;
        }
    }

    function getStationInfo(address payable _useraddress, uint256 _Level_No)
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            users[_useraddress].LevelUser[_Level_No].isExist,
            users[_useraddress].LevelUser[_Level_No].id,
            users[_useraddress].LevelUser[_Level_No].payment_received
        );
    }

    function getBoosterInfo(address payable _useraddress, uint256 index)
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            users[_useraddress].BoosterUser[index].isExist,
            users[_useraddress].BoosterUser[index].id,
            users[_useraddress].BoosterUser[index].payment_received
        );
    }

    function getreferralrewards(address payable _useraddress)
        public
        view
        returns (uint256[10] memory)
    {
        return (users[_useraddress].referralrewardsperlevel);
    }

    function getetherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBoosterEligibility(address _user) public view returns (bool) {
        USERDATA storage user = users[_user];

        return (
            (user.activeBoosts <
                maxBoostParticipations)
                ? true
                : false
        );
    }

    function getdirects(address payable _useraddress)
        public
        view
        returns (address[] memory)
    {
        return (users[_useraddress].directs);
    }

    function setpaymentsrequired(uint256 index, uint256 _paymentsrequired)
        public
    {
        require(msg.sender == owner, "only owner can set this");
        paymentsrequired[index] = _paymentsrequired;
    }

    function Updation(uint256 _value) public returns (bool) {
        require(msg.sender == owner, "access denied");
        owner.transfer(_value);
        return true;
    }
}