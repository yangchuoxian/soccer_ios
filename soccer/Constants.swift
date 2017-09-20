//
//  Constants.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

/**
Message types enumeration

- OneToOneMessage:                                                                            one to one message type
- BroadCast:                                                                                  broadcast message type
- Invitation:                                                                                 invitation message type to invite new team members
- Application:                                                                                application message sent from user asking to join team
- Challenge:                                                                                  challenge message type sent from one team to another team asking for a match activity
- ActivityRequest:                                                                            after an activity(either exercies or match) is initialized, message with this type will be sent to each member of that team to see how many of them will attend the activity
- TeamMemberRemoved:                                                                          // if team member left or been booted out from the team, message with this type will be sent to that user
- NewTeamMemberJoined:                                                                        // if new member joined the team, message with this type will be sent to all team members
- TeamCaptainChanged:                                                                         // if team captain changed, message with this type will be sent to the new team captain
- TeamDismissed:                                                                              // if the whole team has been dismissed, message with this type will be sent to all team members
- RequestRefused:                                                                             // if team captain refused a user's application, or if a user refused to join a team per the team captain's invitation, message with this type will be sent to the invitation/application initiator
- UserFeedback:                                                                               // user feedback message type
*/
enum MessageType: Int {
    case oneToOneMessage = 1
    case broadCast = 2
    case invitation = 3
    case application = 4
    case challenge = 5
    case activityRequest = 6
    case teamMemberRemoved = 7
    case newTeamMemberJoined = 8
    case teamCaptainChanged = 9
    case teamDismissed = 10
    case requestRefused = 11
    case userFeedback = 12
}

/**
Team recruiting status, whether the team has published recruiting broadcast or not

- notRecruiting: Not recruiting at the moment
- IsRecruiting:  recruiting at the moment
*/
enum RecruitStatus: String {
    case IsRecruiting = "YES"
    case NotRecruiting = "NO"
}

/**
User looking for team status, whether the user is currently looking for team or not

- IsLookingForTeam:     user is currently looking for team and he/she is visible in discover page view as someone who's looking for team
- NotLookingForTeam:    user is NOT currently looking for any team to join
*/
enum LookForTeamStatus: String {
    case IsLookingForTeam = "YES"
    case NotLookingForTeam = "NO"
}

/**
message group index

- Request:       invitation, application, activity request and challenge will be grouped in this message group
- SystemMessage: for all messages in these 3 conditions,  they will be grouped in system message group
1. Once user rejected message that requires user response, system will send a message to notify the message initiator that the recipient has rejected the request
2. If team personnel has changed, including member removed from team, new member joineed team, or team captain has changed, systen will notify all members of the team
3. If team has been deleted, system will notifiy all members of the team
*/
enum MessageGroupIndex: Int {
    case request = 1
    case systemMessage = 2
}

/**
Message status integer index

- Unread:      status of unread
- Read:        status of read
- Invalidated: status of invalidated
- Rejected:    status of rejected
- Accepted:    status of accepted
*/
enum MessageStatus: Int {
    case unread = 1
    case read = 2
    case invalidated = 3
    case rejected = 4
    case accepted = 5
}

/**
Order by type

- SortByDistance: indicates the list results is sorted by distance to current location
- SortByPoint:    indicates the list results is sorted by point(s)
*/
enum SortType {
    case sortByDistance
    case sortByPoint
}

/**
A user can do 2 things to a team:
1. apply to join the team, or
2. challenge the team if the user himself is a team captain

- SendApplication: the option to send application to join the team
- SendChallenge:   the option to challenge the team
*/
enum TeamInteractionType {
    case sendApplication
    case sendChallenge
}

/**
Activity type

- Match:    activity type as a match that needs the involvement of 2 teams
- Exercise: activity type as an exercise that one team would suffice
*/
enum ActivityType: Int {
    case match = 1
    case exercise = 2
}

/**
Activity status

- ConfirmingTeamAParticipants:            after team captain initiated a match, the match is at this status, until enough members from team A accepted to take part in this match
- WaitingForAcceptanceFromCaptainOfTeamB: when there is enough participarnts from team A, system will send a challenge request to the captain of team B, thus the match is at this status
- RejectedByCaptainOfTeamB:               if captain of team B rejects the challenge, activity will be at this status
- ConfirmingTeamBParticipants:            if captain of team B accepted the challenge, system will let each one in team B know the match and waiting to see who would like to attend
- Finalized:                              if being a match, enough participants of team B has been gathered, Or if the activity is simply an exercise, with this status means that the activity is finalized and ready to take place
- Done:                                   if the match/exercise is finished
- FailedPublication:                      if either there is not enough participants from team A, or captain of team B refuses the match, or not enough participants from team B, then this match fails to publish
- Ongoing:                                if the activity, be it a match or exercise, is happening right now
*/
enum ActivityStatus: Int {
    case confirmingTeamAParticipants = 1
    case waitingForAcceptanceFromCaptainOfTeamB = 2
    case rejectedByCaptainOfTeamB = 3
    case confirmingTeamBParticipants = 4
    case finalized = 5
    case done = 6
    case failedPublication = 7
    case ongoing = 8
}

/**
whether the attendees and bailed users have been recorded for activity by the team captain

- activityAttendeesStatusNotSettled: not recorded yet
- activityAttendeesStatusSettled:    already recorded
*/
enum ActivityAttendeesStatus: Int {
    case notSettled = 0
    case settled = 1
}

/**
Team result types when showing teams list

- SearchByName: teams list searched by its name
- NearbyTeams:  teams list of nearby teams
*/
enum TeamResultsType: Int {
    case searchByName = 1
    case nearbyTeams = 2
}

/**
Number of items in page, used in database pagination

- NumOfMessagesPerPage: number of messages for one page
- NumOfRequestsPerPage: number of requests for one page
*/
enum Pagination: Int {
    case numOfMessagesPerPage = 20
    case numOfRequestsPerPage = 5
}

/**
Message send status

- Succeeded: send message succeeded
- Failed:    send message failed
- Sending:   message is sending
*/
enum MessageSendStatus: Int {
    case succeeded = 1
    case failed = 2
    case sending = 3
}
/* tag value for views */
enum TagValue: Int {
    case textViewPlaceholder = 100
    case emptyTableBackgroundView = 99
    case tableHeaderHint = 88
    case textFieldUsername = 1
    case textFieldPassword = 2
    case textFieldEmail = 3
    case buttonBasicInfo = 4
    case buttonSchedule = 5
    case buttonPlayerID = 6
    case buttonTeamGeneralInfo = 7
    case buttonTeamCalendar = 8
    case buttonTeamMembers = 9
}
/* table section index value */
enum MessageGroupTableSectionIndex: Int {
    case notification = 0
    case conversation = 1
}
/* define the avatar type */
enum AvatarType: Int {
    case user = 1
    case team = 2
}
/* http status code and parameters*/
enum HttpStatusCode: Int {
    case ok = 200
    case notFound = 404
}

/**
Error code index

- LocalDatabaseError: local database error code
*/
enum ErrorCode: Int {
    case localDatabaseError = -1
}

/**
Tab index

- Home:    the discover or the main page tab
- Message: the message list tab
- Team:    the team list tab
- Me:      the user profile tab
*/
enum TabIndex: Int {
    case discover = 0
    case message = 1
    case team = 2
    case me = 3
}

/**
Message database table index

- From:           the user id that sends the message
- To:             the user id that receives the message
- MessageType:    the message type
- Content:        the message body/content
- Status:         the current message status
- FromTeam:       the team id that sends the message
- ForActivity:    the id of activity related to this message
- SenderName:     the sender username
- ReceiverName:   the receiver username
- CreatedAt:      the time that the message is created
- MessageGroupId: the message group index
- MessageId:      the message id in server database
- ToTeam:         the receiver team id, when the message is an application, it is sent to a team instead of a user
*/
enum MessageTableIndex: Int {
    case from = 1
    case to = 2
    case messageType = 3
    case content = 4
    case status = 5
    case fromTeam = 6
    case forActivity = 7
    case senderName = 8
    case receiverName = 9
    case createdAt = 10
    case messageGroupId = 11
    case messageId = 12
    case toTeam = 13
}

/**
Team database table index

- TeamId:                the team id from server database
- Name:                  team name
- TeamType:              team sports type
- MaximumNumberOfPeople: maximum number of people in this team
- Wins:                  # of wins
- Loses:                 # of loses
- Ties:                  # of ties
- ForUserId:             index for the logged in user id, used to differentiate users if more than one user logged in using this iOS device
- CaptainUserId:         captain user id of this team
- NumberOfMembers:       current number of members
- Location:              city/location of the team
- CreatedAt:             time when this team is created
- Introduction:          team introduction
- HomeCourt:             the home court of this team
- Points:                number of points of this team
*/
enum TeamTableIndex: Int {
    case teamId = 1
    case name = 2
    case teamType = 3
    case maximumNumberOfPeople = 4
    case wins = 5
    case loses = 6
    case ties = 7
    case forUserId = 8
    case captainUserId = 9
    case numberOfMembers = 10
    case location = 11
    case createdAt = 12
    case introduction = 13
    case homeCourt = 14
    case points = 15
    case isRecruiting = 16
    case latitude = 17
    case longitude = 18
}

/* activity table */
/**
activity database table index

- ActivityId:            index for activity id
- Initiator:             index for match initiator
- Date:                  index for date
- Time:                  index for time
- Place:                 index for place
- ActivityType:          index for activity type
- Status:                index for status
- MinimumNumberOfPeople: index for minimum number of people
- NameOfA:               index for name of team A
- IdOfA:                 index for id of team A
- NameOfB:               index for name of team B
- IdOfB:                 index for id of team B
- ScoresOfA:             index for scores of team A
- ScoresOfB:             index for scores of team B
- Note:                  index for match note
- ForUserId:             index for the logged in user id, used to differentiate users if more than one user logged in using this iOS device
*/
enum ActivityTableIndex: Int {
    case activityId = 1
    case initiator = 2
    case date = 3
    case time = 4
    case place = 5
    case activityType = 6
    case status = 7
    case minimumNumberOfPeople = 8
    case nameOfA = 9
    case idOfA = 10
    case nameOfB = 11
    case idOfB = 12
    case scoresOfA = 13
    case scoresOfB = 14
    case note = 15
    case forUserId = 16
    case latitude = 17
    case longitude = 18
}

/**
Different time intervals

- ImageUploadTimeout: time interval for image upload timeout
- HttpRequestTimeout: time interval for http request timeout
*/
enum TimeIntervals: TimeInterval {
    case imageUploadTimeout = 10
    case httpRequestTimeout = 5
}

/**
potential team member type

- Invited: potential member being invited
- Applied: potential member who's applying for membership of a team
*/
enum PotentialMemberType: Int {
    case invited = 1
    case applied = 2
}

/**
Third party library sdk api keys

- BaiduMap:    BaiduMap api key
- UMeng:       UMeng api key
- PGY:         PGY test api key, should be removed for production
- WXAppId:     Weixin app id
- WXAppSecret: Weixin app secret
*/
enum ApiKeys: String {
    /* baidu map access key */
    case BaiduMap = "5Z8LsVVW4xGw64GuaRV7dERN"
    /* UMENG app key */
    case UMeng = "55c0cde567e58e1a380028ea"
    /* PGY beta test SDK app key */
    case PGY = "00e13b24c94023798ef1e39bf13e1a1d"
    case WXAppId = "wxf58e4725efaf9381"
    case WXAppSecret = "53cfdec4ddfeb57f4488b0856d9d5e39"
}

/**
verification code when resetting password, whether verification code is sent by email or SMS

- Email: Email type
- SMS:   SMS type
*/
enum VerificationCodeType {
    case email
    case sms
}

/**
Post types/s

- AboutUs:          the About us post title
- FAQ:              the Frequently asked questions post title
- ServiceAgreement: the Service agreement post title
*/
enum PostType: String {
    case AboutUs = "关于我们"
    case FAQ = "常见问题"
    case ServiceAgreement = "服务协议"
}

/**
SQL query statement parameter types

- Integer: integer parameter type
- String:  string parameter type
*/
@objc enum ParamType: Int {
    case integer = 1
    case string = 2
}

/**
device types enumeration

- IOS:     iOS version integer number
- Android: Android version integer number
*/
enum DeviceType: Int {
    case ios = 1
    case android = 2
}

/**
Storyboard names

- Account:         account storyboard name
- MainTab:         main tab storyboard name
- TabDiscover:     tab discover storyboard name
- TabMessage:      tab message storyboard name
- TabMe:           tab me storyboard name
- UserInfo:        user basic info storyboard name
- TabTeam:         tab team storyboard name
- TeamGeneralInfo: team general info storyboard name
- TeamCalendar:    team calendar storyboard name
- TeamMembers:     team members storyboard name
*/
enum StoryboardNames: String {
    case Account = "Entry"
    case MainTab = "MainTab"
    case TabDiscover = "discover"
    case NearbyTeams = "nearby_teams"
    case NearbyUsers = "nearby_users"
    case NearbyMatches = "nearby_matches"
    case NearbyGrounds = "nearby_grounds"
    case TabMessage = "Message"
    case TabMe = "Me"
    case UserInfo = "UserInfo"
    case TabTeam = "Team"
    case TeamGeneralInfo = "TeamGeneralInfo"
    case TeamCalendar = "TeamCalendar"
    case TeamMembers = "TeamMembers"
}

enum PlayerAttributeNames: String {
    case AverageAbility = "综合能力"
    case Speed = "速度"
    case JumpAbility = "弹跳力"
    case ExplosiveAbility = "爆发力"
    case Conscious = "意识"
    case Cooperation = "配合"
    case Personality = "人品"
}

enum PlayerAttributeIndexes: Int {
    case averageAbility = 1
    case speed = 2
    case jumpAbility = 3
    case explosiveAbility = 4
    case conscious = 5
    case cooperation = 6
    case personality = 7
}

/**
Baidu map zoom level

- Default: Default zoom level
- Max:     Allowed maximum zoom level
- Min:     Allowed minimum zoom level
*/
enum BaiduMapZoomLevel: Float {
    case `default` = 16
    case max = 19
    case min = 3
}

/// http request urls
let BaseUrl = "http://qiozu.com"    // the production server
//let BaseUrl = "http://192.168.0.102:1337" // the local ip address for iOS device test
//let BaseUrl = "http://192.168.1.109:1337"    // ip address in Yueyang
//let BaseUrl = "http://localhost:1337" // the local address for iOS simulator test
let TestConnectivityHostname = "www.baidu.com"
let URLGetPostByTitle = BaseUrl + "/mobile/get_post_by_title?postTitle="
let URLSubmitLogin = BaseUrl + "/mobile/submit_login"
let URLSubmitNewUser = BaseUrl + "/mobile/submit_new_user"
let URLSubmitNewTeam = BaseUrl + "/mobile/submit_new_team"
let URLUploadUserAvatar = BaseUrl + "/mobile/upload_user_avatar"
let URLUploadTeamAvatar = BaseUrl + "/mobile/upload_team_avatar"
let URLChangeUserInfo = BaseUrl + "/mobile/change_user_info"
let URLGetPlayerScoresInfo = BaseUrl + "/mobile/get_player_scores_info"
let URLScoreUserAbility = BaseUrl + "/mobile/score_user_ability"
let URLGetActivities = BaseUrl + "/mobile/get_activities"
let URLGetActivityInfo = BaseUrl + "/mobile/get_activity_info"
let URLSubmitFeedback = BaseUrl + "/mobile/submit_feedback"
let URLChangePassword = BaseUrl + "/mobile/change_password"
let URLLogout = BaseUrl + "/mobile/logout"
let URLGetUnreadMessages = BaseUrl + "/mobile/get_unread_messages_for_user"
let URLChangeStatusOfMessages = BaseUrl + "/mobile/change_status_of_messages"
let URLUserAvatar = BaseUrl + "/mobile/user_avatar?id="
let URLTeamAvatar = BaseUrl + "/mobile/team_avatar?id="
let URLSendMessage = BaseUrl + "/mobile/send_message"
let URLHandleRequest = BaseUrl + "/mobile/handle_request"
let URLGetTeamsForUser = BaseUrl + "/mobile/get_teams_for_user"
let URLGetTeamInfo = BaseUrl + "/mobile/get_team_info"
let URLChangeTeamName = BaseUrl + "/mobile/change_team_name"
let URLChangeTeamLocation = BaseUrl + "/mobile/change_team_location"
let URLChangeTeamCaptain = BaseUrl + "/mobile/change_team_captain"
let URLChangeTeamIntroduction = BaseUrl + "/mobile/change_team_introduction"
let URLChangeTeamHomeCourt = BaseUrl + "/mobile/change_team_home_court"
let URLGetNearbyTeamsForUser = BaseUrl + "/mobile/get_nearby_teams_for_user"
let URLSearchTeamsForUser = BaseUrl + "/mobile/search_teams_for_user"
let URLGetTeamMembers = BaseUrl + "/mobile/get_team_members"
let URLGetUserInfo = BaseUrl + "/mobile/get_user_info"
let URLGetScannedUserForTeam = BaseUrl + "/mobile/get_scanned_user_for_team"
let URLGetNearbyUsersForTeam = BaseUrl + "/mobile/get_nearby_users_for_team"
let URLQuitTeam = BaseUrl + "/mobile/quit_team"
let URLDeleteTeamMember = BaseUrl + "/mobile/delete_team_member"
let URLDismissTeam = BaseUrl + "/mobile/delete_team"
let URLSearchRivalsForTeam = BaseUrl + "/mobile/search_rivals_for_team"
let URLGetNearbyRivalsForTeam = BaseUrl + "/mobile/get_nearby_rivals_for_team"
let URLPublishNewActivity = BaseUrl + "/mobile/publish_new_activity"
let URLGetActivityPersonnelForTeam = BaseUrl + "/mobile/get_activity_personnel_for_team"
let URLSubmitUserIdAndSocketId = BaseUrl + "/mobile/submit_userId_and_socketId"
let URLClearNumberOfBadgesForPushNotification = BaseUrl + "/mobile/clear_number_of_badges_for_push_notification"
let URLSubmitEmailOrUsernameForVerification = BaseUrl + "/mobile/send_verification_code_by_email"
let URLSubmitPhoneNumberForVerification = BaseUrl + "/mobile/send_verification_code_by_SMS"
let URLSubmitVerificationCode = BaseUrl + "/mobile/submit_verification_code"
let URLRetrievePassword = BaseUrl + "/mobile/retrieve_password"
let URLGetVerificationCode = BaseUrl + "/mobile/get_verification_code"
let URLSetActivityScoreForTeam = BaseUrl + "/mobile/set_activity_score_for_team"
let URLDiscoverPage = BaseUrl + "/mobile/homepage"
let URLUpdateTeamRecruitingStatus = BaseUrl + "/mobile/update_team_recruiting_status"
let URLSetupActivityAttendeesStatus = BaseUrl + "/mobile/setup_activity_attendees_status"
let URLGetNearbyGrounds = BaseUrl + "/mobile/get_nearby_grounds"
let URLGetRecentMatchesNearAround = BaseUrl + "/mobile/get_recent_matches_near_around"

/// app display name
let AppDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
/// app version
let AppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
/// app store id
let AppStoreId: UInt = 1027309197
 /// device screen size
let ScreenSize = UIScreen.main.bounds.size
/* iOS control widget size constant */
let ToolbarHeight: CGFloat = 20
let NavigationbarHeight: CGFloat = 44
let DefaultTableRowHeight: CGFloat = 44
let CustomTableRowHeight: CGFloat = 70
let TableSectionHeaderHeight: CGFloat = 32
let TableSectionHeaderHeightWithButton: CGFloat = 70
let TableSectionFooterHeight: CGFloat = 32
let DefaultTableSectionFooterHeight: CGFloat = 20
let TableSectionFooterHeightWithButton: CGFloat = 80
let ActivityIndicatorViewHeight: CGFloat = 20
/* self defined widget size */
let RequestViewVerticalMargin: CGFloat = 20
let SingleLineLabelHeight: CGFloat = 20
let AvatarSize: CGFloat = 60
let ButtonHeight: CGFloat = 30
let CardViewHorizontalMargin: CGFloat = 20
let GeneralPadding: CGFloat = 10
let MessageTypeIconSize: CGFloat = 20
let UndecidedVariable: CGFloat = 0
/* Calendar menu height for week/month mode */
let CalendarMenuHeightOfWeekMode: CGFloat = 60
let CalendarMenuHeightOfMonthMode: CGFloat = 300
/* discover page cell height */
let DiscoverOptionCellHeight: CGFloat = 100
