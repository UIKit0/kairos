/*
 *  AppController.j
 *  Mail
 *
 *  Authors: Ignacio Cases, Ariel Patschiki
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

APPLICATION_VERSION_NUMBER = 0.1;

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <WKTextView/WKTextView.j>

@import "./Categories/VRCategories.j"

@import "./Controllers/MailController.j"
@import "./Controllers/MailSourceViewController.j"
@import "./Controllers/ComposeController.j"
@import "./Controllers/HNAuthController.j"
@import "./Controllers/AboutPanelController.j"
@import "./Controllers/SMEditorToolbarController.j"

@import "./Views/MailboxColumnView.j"
@import "./Views/SMSplitView.j"
@import "./Views/SMAttachmentView.j"
@import "./Views/SMUploadToolbarItem.j"
@import "./Views/SMSmallButton.j"
@import "./Views/SMEditorToolbarView.j"

@import "TNLocalizationCenter.j"
@import "language_registry.js"

@implementation AppController : CPObject
{
    MailController      mailController;
    HNAuthController    authenticationController;
    IBOutlet CPMenuItem viewMenu;
    IBOutlet CPMenuItem readingPaneMenuItem;
    IBOutlet CPMenuItem rightMenuItem;
    IBOutlet CPMenuItem belowMenuItem;
             CPPanel    cachedAboutPanel;
}

- (void)toolbarItemPagerControlChangedValue:(id)sender
{
    var myMailController = [MailController sharedController];
    [myMailController toolbarItemPagerControlChangedValue];
}

- (void)leftPaneFolderRenamingEnded:(id)sender
{
    var myMailSourceViewController = [MailSourceViewController sharedController];
    [myMailSourceViewController leftPaneFolderRenamingEnded];
}

- (void)applicationWillFinishLaunching:(CPNotification)aNotification
{
    // Register user defaults.
    [[CPUserDefaults standardUserDefaults] registerDefaults:[CPDictionary dictionaryWithJSObject:{
            @"SMSplitView Vertical Orientation Mail List Detail Split": NO
        }]];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.

    // Authentication
    authenticationController = [HNAuthController sharedController];
    // Mail
    //mailController = [[MailController alloc] init];
//  var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Mail.cib"]];
//  [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:mailController forKey:CPCibOwner]];

    // Login
//  var loginController = [[LoginController alloc] init];
//  loginController.mailController = mailController;
//  var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Login.cib"]];
//  [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:loginController forKey:CPCibOwner]];

    // Register the localization center
    [[TNLocalizationCenter defaultCenter] setLocale:GENERAL_LANGUAGE_REGISTRY forDomain:TNLocalizationCenterGeneralLocaleDomain];

    // Menu bar customization
//    [self customizeMenu];
}

- (void)awakeFromCib
{
    // Don't use overlay scrollbars.
    [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];

    [viewMenu setTag:@"SMViewMenu"];
    [readingPaneMenuItem setTag:@"SMReadingPaneMenu"];
    [rightMenuItem setTag:@"ParallelView"];
    [belowMenuItem setTag:@"TraditionalView"];
}

- (void)customizeMenu
{
    var editmenuItem = [[[CPApplication sharedApplication] mainMenu] itemWithTitle: @"Edit"];
    [[editmenuItem submenu] setAutoenablesItems:YES];

    var selectAllMenuItem = [[editmenuItem submenu] itemWithTitle:@"Select All"];

    [selectAllMenuItem setTag:@"SelectAll"];
    [selectAllMenuItem setTarget:mailController];
    [self validateMenuItem:selectAllMenuItem];
}

#pragma mark
#pragma mark Menu Item Validation
- (BOOL)validateMenuItem:(id)anItem
{
    switch ([anItem tag])
    {
        case @"SelectAll" :
            return([mailController shouldSelectAll]);
            break;
        default:
            return [anItem isEnabled];
    }
}

#pragma mark
#pragma mark Menu Item Validation
- (IBAction)orderFrontStandardAboutPanel:(id)sender
{
    if (cachedAboutPanel)
    {
        [cachedAboutPanel orderFront:nil];
        return;
    }

    var aboutPanelController = [[AboutPanelController alloc] initWithWindowCibName:@"AboutPanel"],
        aboutPanel = [aboutPanelController window];

    [aboutPanel center];
    [aboutPanel orderFront:self];
    cachedAboutPanel = aboutPanel;
}

@end
