#import "WPMobileStats.h"
#import <Mixpanel/Mixpanel.h>
#import "WordPressComApiCredentials.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "Constants.h"
#import "AccountService.h"

static BOOL hasRecordedAppOpenedEvent = NO;


// General
NSString *const StatsEventAppOpened = @"Application Opened";
NSString *const StatsEventAppClosed = @"Application Closed";
NSString *const StatsEventAppOpenedDueToPushNotification = @"Application Opened Due to Push Notification";

// Top Level Menu Items
NSString *const StatsPropertySidebarClickedReader = @"sidebar_clicked_reader";
NSString *const StatsPropertySidebarClickedNotifications = @"sidebar_clicked_notifications";
NSString *const StatsPropertySidebarSiteClickedPosts = @"sidebar_site_clicked_posts";
NSString *const StatsPropertySidebarSiteClickedPages = @"sidebar_site_clicked_pages";
NSString *const StatsPropertySidebarSiteClickedComments = @"sidebar_site_clicked_comments";
NSString *const StatsPropertySidebarSiteClickedStats = @"sidebar_site_clicked_stats";
NSString *const StatsPropertySidebarSiteClickedViewSite = @"sidebar_site_clicked_view_site";
NSString *const StatsPropertySidebarSiteClickedViewAdmin = @"sidebar_site_clicked_view_admin";
NSString *const StatsPropertySidebarSiteClickedThemes = @"sidebar_site_clicked_themes";
NSString *const StatsPropertySidebarSiteClickedMediaLibrary = @"sidebar_site_clicked_media_library";
NSString *const StatsPropertySidebarClickedSettings = @"sidebar_clicked_settings";
NSString *const StatsPropertySidebarClickedQuickPhoto = @"sidebar_clicked_quick_photo";

// Reader
NSString *const StatsEventReaderOpened = @"Reader - Opened";
NSString *const StatsEventReaderHomePageRefresh = @"Reader - Home Page Refreshed";
NSString *const StatsEventReaderInfiniteScroll = @"Reader - Infinite Scroll";
NSString *const StatsEventReaderSelectedFreshlyPressedTopic = @"Reader - Selected Freshly Pressed Topic";
NSString *const StatsEventReaderSelectedCategory = @"Reader - Selected Category";
NSString *const StatsEventReaderOpenedArticleDetails = @"Reader - Opened Article Details";
NSString *const StatsEventReaderPublishedComment = @"Reader - Published Comment";
NSString *const StatsEventReaderReblogged = @"Reader - Reblogged";
NSString *const StatsEventReaderLikedPost = @"Reader - Liked Post";
NSString *const StatsEventReaderUnlikedPost = @"Reader - Unliked Post";
NSString *const StatsPropertyReaderOpenedFromExternalURL = @"reader_opened_from_external_url";
NSString *const StatsPropertyReaderOpenedFromExternalURLCount = @"reader_opened_from_external_url_count";
NSString *const StatsEventReaderOpenedFromExternalSource = @"Reader - Opened From External Source";

// Reader Detail
NSString *const StatsPropertyReaderDetailClickedPrevious = @"reader_detail_clicked_previous";
NSString *const StatsPropertyReaderDetailClickedNext = @"reader_detail_clicked_next";

// Web View Sharing
NSString *const StatsEventWebviewClickedShowLinkOptions = @"Clicked Show Link Options";
NSString *const StatsEventWebviewSharedArticleViaEmail = @"Shared Article via Email";
NSString *const StatsEventWebviewSharedArticleViaSMS = @"Shared Article via SMS";
NSString *const StatsEventWebviewSharedArticleViaTwitter = @"Shared Article via Twitter";
NSString *const StatsEventWebviewSharedArticleViaFacebook = @"Shared Article via Facebook";
NSString *const StatsEventWebviewSharedArticleViaWeibo = @"Shared Article via Weibo";
NSString *const StatsEventWebviewCopiedArticleDetails = @"Copied Article Details";
NSString *const StatsEventWebviewOpenedArticleInSafari = @"Opened Article in Safari";
NSString *const StatsEventWebviewSentArticleToPocket = @"Sent Article to Pocket";
NSString *const StatsEventWebviewSentArticleToInstapaper = @"Sent Article to Instapaper";
NSString *const StatsEventWebviewSentArticleToGooglePlus = @"Sent Article to Google Plus";

// Notifications
NSString *const StatsPropertyNotificationsOpened = @"notifications_opened";
NSString *const StatsPropertyNotificationsOpenedDetails = @"notifications_opened_details";
NSString *const StatsEventNotificationsClickedManageNotifications = @"Notifications - Manage Button";

// Notifications Detail
NSString *const StatsEventNotificationsDetailClickedReplyButton = @"Notifications Detail - Clicked Reply Button";
NSString *const StatsEventNotificationsDetailRepliedToComment = @"Notifications Detail - Replied to Comment";
NSString *const StatsEventNotificationsDetailApproveComment = @"Notifications Detail - Approve Comment";
NSString *const StatsEventNotificationsDetailUnapproveComment = @"Notifications Detail - Unapprove Comment";
NSString *const StatsEventNotificationsDetailTrashComment = @"Notifications Detail - Trash Comment";
NSString *const StatsEventNotificationsDetailUntrashComment = @"Notifications Detail - Untrash Comment";
NSString *const StatsEventNotificationsDetailFlagCommentAsSpam = @"Notifications Detail - Flag Comment as Spam";
NSString *const StatsEventNotificationsDetailUnflagCommentAsSpam = @"Notifications Detail - Unflagged Comment as Spam";
NSString *const StatsEventNotificationsDetailFollowBlog = @"Notifications Detail - Followed Blog";
NSString *const StatsEventNotificationsDetailUnfollowBlog = @"Notifications Detail - Unfollowed Blog";

// Posts
NSString *const StatsPropertyPostsOpened = @"posts_opened";
NSString *const StatsEventPostsClickedNewPost = @"Posts - Clicked New Post";

// Post Detail
NSString *const StatsPropertyPostDetailClickedEdit = @"clicked_edit";
NSString *const StatsPropertyPostDetailClickedSettings = @"clicked_settings";
NSString *const StatsPropertyPostDetailClickedMedia = @"clicked_media";
NSString *const StatsPropertyPostDetailClickedPreview = @"clicked_preview";
NSString *const StatsPropertyPostDetailClickedMediaOptions = @"clicked_media_options";
NSString *const StatsPropertyPostDetailClickedAddVideo = @"clicked_add_video";
NSString *const StatsPropertyPostDetailClickedAddPhoto = @"clicked_add_photo";
NSString *const StatsPropertyPostDetailClickedShowCategories = @"clicked_show_categories";
NSString *const StatsEventPostDetailClickedKeyboardToolbarBoldButton = @"clicked_keyboard_toolbar_bold_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarItalicButton = @"clicked_keyboard_toolbar_italic_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarUnderlineButton = @"clicked_keyboard_toolbar_underline_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarLinkButton = @"clicked_keyboard_toolbar_link_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarBlockquoteButton = @"clicked_keyboard_toolbar_blockquote_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarDelButton = @"clicked_keyboard_toolbar_del_button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarMoreButton = @"clicked_keyboard_toolbar_more_button";
NSString *const StatsEventPostDetailAddedPhoto = @"Added Photo";
NSString *const StatsEventPostDetailRemovedPhoto = @"Removed Photo";
NSString *const StatsEventPostDetailClickedSchedule = @"Clicked Schedule Button";
NSString *const StatsEventPostDetailClickedSave = @"Clicked Save Button";
NSString *const StatsEventPostDetailClickedUpdate = @"Clicked Update Button";
NSString *const StatsEventPostDetailClickedPublish = @"Clicked Publish Button";
NSString *const StatsEventPostDetailOpenedEditor = @"Opened Editor";
NSString *const StatsEventPostDetailClosedEditor = @"Closed Editor";
NSString *const StatsPropertyPostDetailEditorOpenedBy = @"opened_by";
NSString *const StatsPropertyPostDetailEditorOpenedOpenedByPostsView = @"posts_view";
NSString *const StatsPropertyPostDetailEditorOpenedOpenedByTabBarButton = @"tab_bar_button";
NSString *const StatsPropertyPostDetailClickedBlogSelector = @"clicked_blog_selector";
NSString *const StatsPropertyPostDetailHasExternalKeyboard = @"has_external_keybord";
NSString *const StatsPropertyPostDetailWordCount = @"word_count";
NSString *const StatsPropertyPostDetailWordDiffCount = @"word_diff_count";

// Post Detail - Settings
NSString *const StatsPropertyPostDetailSettingsClickedStatus = @"settings_clicked_status";
NSString *const StatsPropertyPostDetailSettingsClickedVisibility = @"settings_clicked_visibility";
NSString *const StatsPropertyPostDetailSettingsClickedScheduleFor = @"settings_clicked_schedule_for";
NSString *const StatsPropertyPostDetailSettingsClickedPostFormat = @"settings_clicked_post_format";
NSString *const StatsPropertyPostDetailSettingsClickedSetFeaturedImage = @"settings_clicked_set_featured_image";
NSString *const StatsPropertyPostDetailSettingsClickedRemoveFeaturedImage = @"settings_clicked_remove_featured_image";
NSString *const StatsPropertyPostDetailSettingsClickedAddLocation = @"settings_clicked_add_location";
NSString *const StatsPropertyPostDetailSettingsClickedUpdateLocation = @"settings_clicked_update_location";
NSString *const StatsPropertyPostDetailSettingsClickedRemoveLocation = @"settings_clicked_remove_location";

// Pages
NSString *const StatsPropertyPagesOpened = @"pages_opened";
NSString *const StatsEventPagesClickedNewPage = @"Pages - Clicked New Page";

// Comments
NSString *const StatsEventCommentsViewCommentDetails = @"Comments - View Comment Details";

// Comment Detail
NSString *const StatsEventCommentDetailApprove = @"Comment Detail - Approve Comment";
NSString *const StatsEventCommentDetailUnapprove = @"Comment Detail - Unapprove Comment";
NSString *const StatsEventCommentDetailDelete = @"Comment Detail - Delete Comment";
NSString *const StatsEventCommentDetailFlagAsSpam = @"Comment Detail - Flag Comment as Spam";
NSString *const StatsEventCommentDetailEditComment = @"Comment Detail - Edit Comment";
NSString *const StatsEventCommentDetailClickedReplyToComment = @"Comment Detail - Clicked Reply to Comment";
NSString *const StatsEventCommentDetailRepliedToComment = @"Comment Detail - Replied to Comment";


// Settings
NSString *const StatsEventSettingsRemovedBlog = @"Settings - Remove Blog";
NSString *const StatsEventSettingsClickedEditBlog = @"Settings - Clicked Edit Blog";
NSString *const StatsEventSettingsClickedAddBlog = @"Settings - Clicked Add Blog";
NSString *const StatsEventSettingsSignedOutOfDotCom = @"Settings - Signed Out of Wordpress.com";
NSString *const StatsEventSettingsClickedSignIntoDotCom = @"Settings - Clicked Sign Into Wordpress.com";
NSString *const StatsEventSettingsClickedSignOutOfDotCom = @"Settings - Clicked Sign Out of Wordpress.com";
NSString *const StatsEventSettingsMediaClickedImageResize = @"Settings - Media - Clicked Image Resize";
NSString *const StatsEventSettingsMediaClickedVideoQuality = @"Settings - Media - Clicked Video Quality";
NSString *const StatsEventSettingsMediaClickedVideoContent = @"Settings - Media - Clicked Video Content";
NSString *const StatsEventSettingsClickedManageNotifications = @"Settings - Clicked Manage Notifications";
NSString *const StatsEventSettingsEnabledSounds = @"Settings - Enabled Sounds";
NSString *const StatsEventSettingsDisabledSounds = @"Settings - Disabled Sounds";
NSString *const StatsEventSettingsClickedAbout = @"Settings - Clicked About";

// Manage Notifications
NSString *const StatsEventManageNotificationsTurnOn = @"Manage Notifications - Turn On Notifications";
NSString *const StatsEventManageNotificationsTurnOff = @"Manage Notifications - Turn Off Notifications";
NSString *const StatsEventManageNotificationsTurnOffForOneHour = @"Manage Notifications - Turn Off Notifications For One Hour";
NSString *const StatsEventManageNotificationsTurnOffUntil8AM = @"Manage Notifications - Turn Off Notifications Until 8AM";
NSString *const StatsEventManageNotificationsEnabledFollowNotifications = @"Manage Notifications - Enable Follow Notifications";
NSString *const StatsEventManageNotificationsDisabledFollowNotifications = @"Manage Notifications - Disabled Follow Notifications";
NSString *const StatsEventManageNotificationsEnabledAchievementsNotifications = @"Manage Notifications - Enable Achievements Notifications";
NSString *const StatsEventManageNotificationsDisabledAchievementsNotifications = @"Manage Notifications - Disabled Achievements Notifications";
NSString *const StatsEventManageNotificationsEnabledCommentNotifications = @"Manage Notifications - Enable Comment Notifications";
NSString *const StatsEventManageNotificationsDisabledCommentNotifications = @"Manage Notifications - Disabled Comment Notifications";
NSString *const StatsEventManageNotificationsEnabledReblogNotifications = @"Manage Notifications - Enable Reblog Notifications";
NSString *const StatsEventManageNotificationsDisabledReblogNotifications = @"Manage Notifications - Disabled Reblog Notifications";
NSString *const StatsEventManageNotificationsEnabledLikeNotifications = @"Manage Notifications - Enable Like Notifications";
NSString *const StatsEventManageNotificationsDisabledLikeNotifications = @"Manage Notifications - Disabled Like Notifications";
NSString *const StatsEventManageNotificationsEnabledBlogNotifications = @"Manage Notifications - Enable Blog Notifications";
NSString *const StatsEventManageNotificationsDisabledBlogNotifications = @"Manage Notifications - Disabled Blog Notifications";

// Quick Photo
NSString *const StatsEventQuickPhotoOpened = @"Quick Photo - Opened";
NSString *const StatsEventQuickPhotoPosted = @"Quick Photo - Posted";

// NUX First Walkthrough 
NSString *const StatsEventNUXFirstWalkthroughOpened = @"NUX - First Walkthrough - Opened";
NSString *const StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount = @"NUX - First Walkthrough - Skipped to Create Account";
NSString *const StatsEventNUXFirstWalkthroughClickedLostPassword = @"NUX - First Walkthrough - Lost Password";
NSString *const StatsEventNUXFirstWalkthroughClickedInfo = @"NUX - First Walkthrough - Clicked Info";
NSString *const StatsEventNUXFirstWalkthroughClickedCreateAccount = @"NUX - First Walkthrough - Clicked Create Account";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithoutUrl = @"NUX - First Walkthrough - Signed In Without URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithUrl = @"NUX - First Walkthrough - Signed In With URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInForDotCom = @"NUX - First Walkthrough - Signed In For WordPress.com";
NSString *const StatsEventNUXFirstWalkthroughSignedInForSelfHosted = @"NUX - First Walkthrough - Signed In For Self Hosted Site";
NSString *const StatsEventNUXFirstWalkthroughClickedEnableXMLRPCServices = @"NUX - First Walkthrough - Clicked Enable XML-RPC Services";
NSString *const StatsEventNUXFirstWalkthroughClickedNeededHelpOnError = @"NUX - First Walkthrough - Clicked Needed Help on Error";
NSString *const StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack = @"NUX - First Walkthrough - User Signed In To Blog With Jetpack";
NSString *const StatsEventNUXFirstWalkthroughUserConnectedToJetpack = @"NUX - First Walkthrough - User Connected to Jetpack";
NSString *const StatsEventNUXFirstWalkthroughUserSkippedConnectingToJetpack = @"NUX - First Walkthrough - User Skipped Connecting to Jetpack";


// NUX Create Account
NSString *const StatsEventAccountCreationOpenedFromTabBar = @"NUX - Create Account Opened From Tab Bar";
NSString *const StatsEventNUXCreateAccountOpened = @"NUX - Create Account - Opened";
NSString *const StatsEventNUXCreateAccountClickedCancel = @"NUX - Create Account - Clicked Cancel";
NSString *const StatsEventNUXCreateAccountClickedHelp = @"NUX - Create Account - Clicked Help";
NSString *const StatsEventNUXCreateAccountClickedAccountPageNext = @"NUX - Create Account - Clicked Account Page Next";
NSString *const StatsEventNUXCreateAccountClickedSitePageNext = @"NUX - Create Account - Clicked Site Page Next";
NSString *const StatsEventNUXCreateAccountClickedSitePagePrevious = @"NUX - Create Account - Clicked Site Page Previous";
NSString *const StatsEventNUXCreateAccountCreatedAccount = @"NUX - Create Account - Created Account";
NSString *const StatsEventNUXCreateAccountClickedReviewPagePrevious = @"NUX - Create Account - Clicked Review Page Previous";
NSString *const StatsEventNUXCreateAccountClickedViewLanguages = @"NUX - Create Account - Viewed Languages";
NSString *const StatsEventNUXCreateAccountChangedDefaultURL = @"NUX - Create Account - Changed Default URL";

// Ådd Blogs Screen
NSString *const StatsEventAddBlogsOpened = @"Add Blogs - Opened";
NSString *const StatsEventAddBlogsClickedSelectAll = @"Add Blogs - Clicked Select All";
NSString *const StatsEventAddBlogsClickedDeselectAll = @"Add Blogs - Clicked Deselect All";
NSString *const StatsEventAddBlogsClickedAddSelected = @"Add Blogs - Clicked Add Selected";

// Stats
NSString *const StatsEventStatsClickedOnWebVersion = @"Stats - Clicked on Web Version";


// Super Properties

// General
NSString *const StatsSuperPropertyNumberOfTimesOpenedReader = @"number_of_times_opened_reader";
NSString *const StatsSuperPropertyNumberOfTimesOpenedNotifications = @"number_of_times_opened_notifications";
NSString *const StatsSuperPropertyNumberOfTimesOpenedStats = @"number_of_times_opened_stats";
NSString *const StatsSuperPropertyNumberOfTimesOpenedViewAdmin = @"number_of_times_opened_view_admin";

// Reader
NSString *const StatsSuperPropertyNumberOfItemsOpenedInReader = @"number_of_items_opened_in_reader";
NSString *const StatsSuperPropertyNumberOfItemsLikedInReader = @"number_of_items_liked_in_reader";
NSString *const StatsSuperPropertyNumberOfItemsUnlikedInReader = @"number_of_items_unliked_in_reader";
NSString *const StatsSuperPropertyNumberOfItemsRebloggedInReader = @"number_of_items_reblogged_in_reader";

// Sharing
NSString *const StatsSuperPropertyNumberOfItemsShared = @"number_of_items_shared";
NSString *const StatsSuperPropertyNumberOfItemsSharedViaEmail = @"number_of_items_shared_via_email";
NSString *const StatsSuperPropertyNumberOfItemsSharedViaSMS = @"number_of_items_shared_via_sms";
NSString *const StatsSuperPropertyNumberOfItemsSharedViaTwitter = @"number_of_items_shared_via_twitter";
NSString *const StatsSuperPropertyNumberOfItemsSharedViaFacebook = @"number_of_items_shared_via_facebook";
NSString *const StatsSuperPropertyNumberOfItemsSharedViaWeibo = @"number_of_items_shared_via_weibo";
NSString *const StatsSuperPropertyNumberOfItemsSentToPocket = @"number_of_items_sent_to_pocket";
NSString *const StatsSuperPropertyNumberOfItemsSentToInstapaper = @"number_of_items_sent_to_instapaper";
NSString *const StatsSuperPropertyNumberOfItemsSentToGooglePlus = @"number_of_items_sent_to_google_plus";

// Notifications
NSString *const StatsSuperPropertyNumberOfTimesOpenedNotificationDetails = @"number_of_times_opened_notification_details";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInActions = @"number_of_notifications_resulting_in_actions";
NSString *const StatsSuperPropertyNumberOfNotificationsRepliedTo = @"number_of_notifications_replied_to";
NSString *const StatsSuperPropertyNumberOfNotificationsApproved = @"number_of_notifications_approved";
NSString *const StatsSuperPropertyNumberOfNotificationsUnapproved = @"number_of_notifications_unapproved";
NSString *const StatsSuperPropertyNumberOfNotificationsTrashed = @"number_of_notifications_trashed";
NSString *const StatsSuperPropertyNumberOfNotificationsUntrashed = @"number_of_notifications_untrashed";
NSString *const StatsSuperPropertyNumberOfNotificationsFlaggedAsSpam = @"number_of_notifications_flagged_as_spam";
NSString *const StatsSuperPropertyNumberOfNotificationsUnflaggedAsSpam = @"number_of_notifications_unflagged_as_spam";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAFollow = @"number_of_notifications_resulting_in_a_follow";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAnUnfollow = @"number_of_notifications_resulting_in_an_unfollow";

// Posts
NSString *const StatsSuperPropertyNumberOfPostsPublished = @"number_of_posts_published";
NSString *const StatsSuperPropertyNumberOfPostsUpdated = @"number_of_posts_updated";
NSString *const StatsSuperPropertyNumberOfPhotosAddedToPosts = @"number_of_photos_added_to_post";
NSString *const StatsSuperPropertyNumberOfVideosAddedToPosts = @"number_of_videos_added_to_post";
NSString *const StatsSuperPropertyNumberOfFeaturedImagesAssignedToPosts = @"number_of_featured_images_assigned_to_post";
NSString *const StatsSuperPropertyNumberOfPostsWithPhotos = @"number_of_posts_with_photos";
NSString *const StatsSuperPropertyNumberOfPostsWithVideos = @"number_of_posts_with_videos";
NSString *const StatsSuperPropertyNumberOfPostsWithCategories = @"number_of_posts_with_categories";
NSString *const StatsSuperPropertyNumberOfPostsWithTags = @"number_of_posts_with_tags";

@interface WPMobileStats() {
    NSMutableDictionary *_aggregatedEventProperties;
}

@end

@implementation WPMobileStats

- (id)init
{
    self = [super init];
    if (self) {
        _aggregatedEventProperties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (WPMobileStats *)sharedInstance
{
    static WPMobileStats *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (void)initializeStats
{
    [Mixpanel sharedInstanceWithToken:[WordPressComApiCredentials mixpanelAPIToken]];

    // Tracking session count will help us isolate users who just installed the app
    NSUInteger sessionCount = [[[[Mixpanel sharedInstance] currentSuperProperties] objectForKey:@"session_count"] intValue];
    sessionCount++;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];
    NSDictionary *properties = @{
                                 @"platform": @"iOS",
                                 @"session_count": @(sessionCount),
                                 @"connected_to_dotcom": @(account != nil),
                                 @"number_of_blogs" : @([Blog countWithContext:[[ContextManager sharedInstance] mainContext]]) };
    [[Mixpanel sharedInstance] registerSuperProperties:properties];
    
    NSString *username = account.username;
    if (account && [username length] > 0) {
        [[Mixpanel sharedInstance] identify:username];
        [[Mixpanel sharedInstance].people increment:@"Application Opened" by:@(1)];
        [[Mixpanel sharedInstance].people set:@{ @"$username": username, @"$first_name" : username }];
    }
}

+ (void)pauseSession
{
    [self clearPropertiesForAllEvents];
    hasRecordedAppOpenedEvent = NO;
}

+ (void)recordAppOpenedForEvent:(NSString *)event {
    if (!hasRecordedAppOpenedEvent) {
        [self trackEventForSelfHostedAndWPCom:event];
    }
    hasRecordedAppOpenedEvent = YES;
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event properties:properties];
}

+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPComWithSavedProperties:event];
}

+ (void)trackEventForWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForWPCom:event];
}

+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForWPCom:event properties:properties];
}

+ (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForWPComWithSavedProperties:event];
}

+ (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    @autoreleasepool {
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
        [conn start];
    }
}

+ (void)clearPropertiesForAllEvents
{
    [[self sharedInstance] clearPropertiesForAllEvents];
}

+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] incrementProperty:property forEvent:event];
}

+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] setValue:value forProperty:property forEvent:event];
}

+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] flagProperty:property forEvent:event];
}

+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] unflagProperty:property forEvent:event];
}

+ (void)flagSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagSuperProperty:property];
}

+ (void)incrementSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementSuperProperty:property];
}

+ (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forSuperProperty:property];
}

+ (void)flagPeopleProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleProperty:property];
}

+ (void)incrementPeopleProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleProperty:property];
}

+ (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleProperty:property];
}

+ (void)flagPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleAndSuperProperty:property];
}

+ (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleAndSuperProperty:property];
}

+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleAndSuperProperty:property];
}

#pragma mark - Private Methods

- (BOOL)connectedToWordPressDotCom
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return [[defaultAccount restApi] hasCredentials];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[Mixpanel sharedInstance] track:event properties:properties];
}

- (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
}

- (void)trackEventForWPCom:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event];
    }
}

- (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:properties];
    }
}

- (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
    }
}

- (void)clearPropertiesForAllEvents
{
    [_aggregatedEventProperties removeAllObjects];
}

- (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    NSNumber *currentValue = [self property:property forEvent:event];
    int newValue;
    if (currentValue == nil) {
        newValue = 1;
    } else {
        newValue = [currentValue intValue];
        newValue++;
    }
    
    [self saveProperty:property withValue:@(newValue) forEvent:event];
}

- (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(YES) forEvent:event];
}

- (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(NO) forEvent:event];
}

- (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:value forEvent:event];
}

- (void)flagSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = @(YES);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}


- (void)incrementSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = value;
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)flagPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{ property : @(YES) }];
}

- (void)incrementPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{property: value}];
}

- (void)flagPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self flagPeopleProperty:property];
    [self flagSuperProperty:property];
}

- (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self incrementPeopleProperty:property];
    [self incrementSuperProperty:property];
}

- (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [self setValue:value forPeopleProperty:property];
    [self setValue:value forSuperProperty:property];
}


- (id)property:(NSString *)property forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    return [eventProperties objectForKey:property];
}

- (void)saveProperty:(NSString *)property withValue:(id)value forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    if (eventProperties == nil) {
        eventProperties = [[NSMutableDictionary alloc] init];
        [_aggregatedEventProperties setValue:eventProperties forKey:event];
    }
    
    [eventProperties setValue:value forKey:property];
}

- (NSDictionary *)propertiesForEvent:(NSString *)event
{
    return [_aggregatedEventProperties objectForKey:event];
}


@end
