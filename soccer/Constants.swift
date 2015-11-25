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
    case OneToOneMessage = 1
    case BroadCast = 2
    case Invitation = 3
    case Application = 4
    case Challenge = 5
    case ActivityRequest = 6
    case TeamMemberRemoved = 7
    case NewTeamMemberJoined = 8
    case TeamCaptainChanged = 9
    case TeamDismissed = 10
    case RequestRefused = 11
    case UserFeedback = 12
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
    case Request = 1
    case SystemMessage = 2
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
    case Unread = 1
    case Read = 2
    case Invalidated = 3
    case Rejected = 4
    case Accepted = 5
}

/**
Order by type

- SortByDistance: indicates the list results is sorted by distance to current location
- SortByPoint:    indicates the list results is sorted by point(s)
*/
enum SortType {
    case SortByDistance
    case SortByPoint
}

/**
A user can do 2 things to a team:
1. apply to join the team, or
2. challenge the team if the user himself is a team captain

- SendApplication: the option to send application to join the team
- SendChallenge:   the option to challenge the team
*/
enum TeamInteractionType {
    case SendApplication
    case SendChallenge
}

/**
Activity type

- Match:    activity type as a match that needs the involvement of 2 teams
- Exercise: activity type as an exercise that one team would suffice
*/
enum ActivityType: Int {
    case Match = 1
    case Exercise = 2
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
    case ConfirmingTeamAParticipants = 1
    case WaitingForAcceptanceFromCaptainOfTeamB = 2
    case RejectedByCaptainOfTeamB = 3
    case ConfirmingTeamBParticipants = 4
    case Finalized = 5
    case Done = 6
    case FailedPublication = 7
    case Ongoing = 8
}

/**
whether the attendees and bailed users have been recorded for activity by the team captain

- activityAttendeesStatusNotSettled: not recorded yet
- activityAttendeesStatusSettled:    already recorded
*/
enum ActivityAttendeesStatus: Int {
    case NotSettled = 0
    case Settled = 1
}

/**
Team result types when showing teams list

- SearchByName: teams list searched by its name
- NearbyTeams:  teams list of nearby teams
*/
enum TeamResultsType: Int {
    case SearchByName = 1
    case NearbyTeams = 2
}

/**
Number of items in page, used in database pagination

- NumOfMessagesPerPage: number of messages for one page
- NumOfRequestsPerPage: number of requests for one page
*/
enum Pagination: Int {
    case NumOfMessagesPerPage = 20
    case NumOfRequestsPerPage = 5
}

/**
Message send status

- Succeeded: send message succeeded
- Failed:    send message failed
- Sending:   message is sending
*/
enum MessageSendStatus: Int {
    case Succeeded = 1
    case Failed = 2
    case Sending = 3
}
/* tag value for views */
enum TagValue: Int {
    case TextViewPlaceholder = 100
    case EmptyTableBackgroundView = 99
    case TableHeaderHint = 88
    case TextFieldUsername = 1
    case TextFieldPassword = 2
    case TextFieldEmail = 3
    case ButtonBasicInfo = 4
    case ButtonSchedule = 5
    case ButtonPlayerID = 6
    case ButtonTeamGeneralInfo = 7
    case ButtonTeamCalendar = 8
    case ButtonTeamMembers = 9
}
/* table section index value */
enum MessageGroupTableSectionIndex: Int {
    case Notification = 0
    case Conversation = 1
}
/* define the avatar type */
enum AvatarType: Int {
    case User = 1
    case Team = 2
}
/* http status code and parameters*/
enum HttpStatusCode: Int {
    case OK = 200
    case NotFound = 404
}

/**
Error code index

- LocalDatabaseError: local database error code
*/
enum ErrorCode: Int {
    case LocalDatabaseError = -1
}

/**
Tab index

- Home:    the discover or the main page tab
- Message: the message list tab
- Team:    the team list tab
- Me:      the user profile tab
*/
enum TabIndex: Int {
    case Discover = 0
    case Message = 1
    case Team = 2
    case Me = 3
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
    case From = 1
    case To = 2
    case MessageType = 3
    case Content = 4
    case Status = 5
    case FromTeam = 6
    case ForActivity = 7
    case SenderName = 8
    case ReceiverName = 9
    case CreatedAt = 10
    case MessageGroupId = 11
    case MessageId = 12
    case ToTeam = 13
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
    case TeamId = 1
    case Name = 2
    case TeamType = 3
    case MaximumNumberOfPeople = 4
    case Wins = 5
    case Loses = 6
    case Ties = 7
    case ForUserId = 8
    case CaptainUserId = 9
    case NumberOfMembers = 10
    case Location = 11
    case CreatedAt = 12
    case Introduction = 13
    case HomeCourt = 14
    case Points = 15
    case IsRecruiting = 16
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
    case ActivityId = 1
    case Initiator = 2
    case Date = 3
    case Time = 4
    case Place = 5
    case ActivityType = 6
    case Status = 7
    case MinimumNumberOfPeople = 8
    case NameOfA = 9
    case IdOfA = 10
    case NameOfB = 11
    case IdOfB = 12
    case ScoresOfA = 13
    case ScoresOfB = 14
    case Note = 15
    case ForUserId = 16
    case Latitude = 17
    case Longitude = 18
}

/**
Different time intervals

- ImageUploadTimeout: time interval for image upload timeout
- HttpRequestTimeout: time interval for http request timeout
*/
enum TimeIntervals: NSTimeInterval {
    case ImageUploadTimeout = 10
    case HttpRequestTimeout = 5
}

/**
potential team member type

- Invited: potential member being invited
- Applied: potential member who's applying for membership of a team
*/
enum PotentialMemberType: Int {
    case Invited = 1
    case Applied = 2
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
    case Email
    case SMS
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
    case Integer = 1
    case String = 2
}

/**
device types enumeration

- IOS:     iOS version integer number
- Android: Android version integer number
*/
enum DeviceType: Int {
    case IOS = 1
    case Android = 2
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
    case AverageAbility = 1
    case Speed = 2
    case JumpAbility = 3
    case ExplosiveAbility = 4
    case Conscious = 5
    case Cooperation = 6
    case Personality = 7
}

/**
Baidu map zoom level

- Default: Default zoom level
- Max:     Allowed maximum zoom level
- Min:     Allowed minimum zoom level
*/
enum BaiduMapZoomLevel: Float {
    case Default = 16
    case Max = 19
    case Min = 3
}

/// http request urls
//let BaseUrl = "http://www.qiozu.com"    // the production server
let BaseUrl = "http://192.168.0.102:1337" // the local ip address for iOS device test
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
let AppDisplayName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as! String
/// app version
let AppVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
/// app store id
let AppStoreId: UInt = 1027309197
 /// device screen size
let ScreenSize = UIScreen.mainScreen().bounds.size
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