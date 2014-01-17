//
//  EditPostViewControllerTest.m
//  WordPress
//
//  Created by Jorge Bernal on 14/01/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "CoreDataTestHelper.h"
#import "Blog.h"
#import "Post.h"
#import "Category.h"
#import "AsyncTestHelper.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "UIKitTestHelper.h"
#import "EditPostViewController_Internal.h"
#import "WPSegmentedSelectionTableViewController.h"

@interface EditPostViewControllerTest : XCTestCase

@end

@implementation EditPostViewControllerTest {
    EditPostViewController *_editor;
    UINavigationController *_navigationController;
    AsyncTestHelper *_presentationHelper;
}

- (void)setUp
{
    [super setUp];

    /* Ignore network request to avoid reader auto refresh */
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:nil statusCode:200 responseTime:0 headers:nil];
    }];

    __block WPAccount *account = nil;
    CoreDataPerformAndWaitForSave(^{
        account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token" context:[ContextManager sharedInstance].mainContext];
    });

    [WPAccount setDefaultWordPressComAccount:account];

    NSDictionary *blogDictionary = @{@"blogid": @(1),
                                     @"url": @"http://test.wordpress.com/",
                                     @"xmlrpc": @"http://test.wordpress.com/xmlrpc.php"};
    __unused Blog *_blog = [account findOrCreateBlogFromDictionary:blogDictionary withContext:[ContextManager sharedInstance].mainContext];
    __unused Category *category = [Category createOrReplaceFromDictionary:@{@"categoryId": @1, @"categoryName": @"Uncategorized", @"parentId": @0} forBlog:_blog];
    category = [Category createOrReplaceFromDictionary:@{@"categoryId": @2, @"categoryName": @"Test", @"parentId": @0} forBlog:_blog];

    CoreDataPerformAndWaitForSave(^{
        [[ContextManager sharedInstance] saveContext:_blog.managedObjectContext];
    });

    _editor = [[EditPostViewController alloc] initWithDraftForLastUsedBlog];
    _navigationController = [[UINavigationController alloc] initWithRootViewController:_editor];

    _presentationHelper = [AsyncTestHelper new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerReadyWithNotification:) name:EditPostViewControllerRevisionCreatedNotificationName object:nil];

    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    if (root.presentedViewController) {
        [root.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    [root presentViewController:_navigationController animated:NO completion:nil];
    [_editor view];
    AsyncTestHelperWait(_presentationHelper);
}

- (void)tearDown
{
    [_navigationController dismissViewControllerAnimated:NO completion:nil];

    [[CoreDataTestHelper sharedHelper] reset];

    // Remove cached __defaultDotcomAccount, no need to remove core data value
    // Exception occurs if attempted: the persistent stores are swapped in reset
    // and the contexts are destroyed
    [WPAccount removeDefaultWordPressComAccountWithContext:nil];

    [OHHTTPStubs removeAllRequestHandlers];

    [super tearDown];
}

- (void)testControllerPresented {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *root = window.rootViewController;
    XCTAssert([root isKindOfClass:[UITabBarController class]], @"root controller should be a tab bar");
    UIViewController *presented = root.presentedViewController;
    XCTAssert([presented isKindOfClass:[UINavigationController class]], @"presented controller should be navigation");
    UIViewController *topController = [(UINavigationController *)presented topViewController];
    XCTAssert([topController isKindOfClass:[EditPostViewController class]], @"top controller should be an editor");
}

- (void)testTypePost {
    XCTAssertNotNil(_editor.post);
    XCTAssertNil(_editor.post.postTitle);

    // Enter a title
    [_editor.titleTextField typeText:@"A title"];

    // Type some content
    [_editor.textView typeText:@"A new post"];

    // Switch to post options
    UINavigationController *navController = (UINavigationController *)[[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentedViewController];
    XCTAssert([[navController topViewController] isKindOfClass:[EditPostViewController class]], @"top controller should be the editor");
    [_editor showSettings];
    XCTAssert([[navController topViewController] isKindOfClass:[PostSettingsViewController class]], @"top controller should be the editor settings");

    // Are categories displayed?
    PostSettingsViewController *settings = (PostSettingsViewController *)[navController topViewController];
    UITableView *tableView = (UITableView *)settings.view.subviews[0];
    XCTAssert([tableView isKindOfClass:[UITableView class]]);
    XCTAssertNotNil(tableView.delegate);
    [tableView.delegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    AsyncTestHelperSleep(1);

    WPSegmentedSelectionTableViewController *categoriesController = (WPSegmentedSelectionTableViewController *)[navController topViewController];
    XCTAssert([categoriesController isKindOfClass:[WPSegmentedSelectionTableViewController class]], @"top controller should be category selector");
    UITableView *categoriesTable = categoriesController.tableView;
    XCTAssertEqual([categoriesTable numberOfSections], 1);
    XCTAssertEqual([categoriesTable numberOfRowsInSection:0], 2);

    // Select a category
    [categoriesTable.delegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [categoriesController viewWillDisappear:NO];
    [navController popToViewController:settings animated:NO];
    XCTAssert([[navController topViewController] isKindOfClass:[PostSettingsViewController class]], @"top controller should be the editor settings");

    // Enter some tags
    UITextField *tagsTextField = nil;
    XCTAssertNoThrow(tagsTextField = [settings performSelector:@selector(tagsTextField)]);
    XCTAssertNotNil(tagsTextField);
    XCTAssert([tagsTextField isKindOfClass:[UITextField class]]);
    [tagsTextField typeText:@"tag1, tag2"];

    // Check if the post has all the edits
    AbstractPost *post = _editor.post;
    XCTAssertEqualObjects(@"A title", post.postTitle);
    XCTAssertEqualObjects(@"A new post", post.content);
    XCTAssertEqual(1u, [[((Post *)post) categories] count]);
    XCTAssertEqualObjects(@"tag1, tag2", [((Post *)post) tags]);
}

- (void)testFormattingOptions {
    // Type some text

    // Bold inserts strong tag, selection inside the tag

    // Select some text, tap bold, strong surrounds the text
}

- (void)controllerReadyWithNotification:(NSNotification *)notification {
    [_presentationHelper notify];
}
@end
