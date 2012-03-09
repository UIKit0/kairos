/*
 *  MailController.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
*/

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>
@import <AppKit/CPWindowController.j>
@import "../Models/SMEmail.j"
@import "../Models/Email.j"
@import "../Models/SMEmailService.j"
@import "../Models/SMMailAccount.j"
@import "../Models/SMMailbox.j"
@import "../Models/SMMailHeader.j"
@import "../Models/SMMailContent.j"
@import "../Views/SMEmailSubjectView.j"
@import "../Views/SMPagerView.j"
@import "../Controllers/HNAuthController.j"
@import "../Categories/CPDate+Formatting.j"
@import "../EventsFromServerReceiver.j"


var tableTestDragType = "tableTestDragType";

SMEmailTableViewRowHeightParallelView = 40;
SMEmailTableViewRowHeightTraditionalView = 23;
SMSubjectTableColumnWidthParallelView = 440;

var IsReadImage,
    SwitcherTraditionalViewOnImage,
    SwitcherTraditionalViewOffImage,
    SwitcherParallelViewOnImage,
    SwitcherParallelViewOffImage,
    SharedMailController = nil;

@implementation MailController : CPWindowController
{
    @outlet CPScrollView    scrollViewEmails;

    @outlet CPWindow        theWindow @accessors;
    @outlet CPToolbar       toolbar;
    @outlet CPTextField     loadingLabel;
    @outlet CPWebView       webView;
    @outlet CPTextField     fromContent;
    @outlet CPTextField     toContent;
    @outlet CPTextField     dateContent;
    @outlet CPTextField     subjectContent;
    @outlet CPTextField     fromLabel;
    @outlet CPTextField     toLabel;
    @outlet CPTextField     dateLabel;
    @outlet CPTextField     subjectLabel;
    @outlet CPSplitView     mailSplitView;
    @outlet CPTableView     emailsHeaderView;

    @outlet MailSourceViewController mailSourceController;

    IBOutlet SMEmailSubjectView parallelDataView;
    IBOutlet CPTableColumn  unread;
    IBOutlet CPTableColumn  fromTableColumn;
    IBOutlet CPTableColumn  subjectTableColumn;
    IBOutlet CPTableColumn  dateTableColumn;

    CPView                  originalSubjectTableColumnView;
    int                     originalSubjectTableColumnWidth;

    IBOutlet CPImageView    testImageView;
    ComposeController       _composeController;

    SMMailAccount           mailAccount @accessors;
    ServerConnection        _serverConnection;

    SMMailbox               selectedMailbox @accessors;
    SMEmail                 selectedEmail @accessors;
    BOOL                    justSelect;
    BOOL                    justSelectMailboxes @accessors;
    CPDictionary            items;

    // This should be moved to the App Controller
    CPString                displayedViewKey @accessors;
    @outlet CPView          logoView;

    EventsFromServerReceiver    _eventsFromServerReceiver;
    CPWindow                _connectionErrorWholeScreenWindow;
    CPPanel                 _connectionErrorFloatingWindow;
}

+ (void)initialize
{
    // Switcher images
    IsReadImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_marker.png"] size:CGSizeMake(11, 12)];

    SwitcherTraditionalViewOnImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherTraditionalViewOnIcon.png"] size:CGSizeMake(19, 16)];
    SwitcherTraditionalViewOffImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherTraditionalViewOffIcon.png"] size:CGSizeMake(19, 16)];
    SwitcherParallelViewOnImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherParallelViewOnIcon.png"] size:CGSizeMake(19, 16)];
    SwitcherParallelViewOffImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherParallelViewOffIcon.png"] size:CGSizeMake(19, 16)];
}

+ (MailController)sharedController
{
    return SharedMailController;
}

#pragma mark ViewControler cyle
- (void)awakeFromCib
{
    if (!SharedMailController)
    {
        SharedMailController = self;
    }


    [theWindow setFullBridge:YES];

    var bundle      = [CPBundle mainBundle],
        defaults    = [CPUserDefaults standardUserDefaults],
        center      = [CPNotificationCenter defaultCenter];

    /* register logs */
    CPLogRegister(CPLogConsole, [defaults objectForKey:@"VRKairosConsoleDebugLevel"]);

    // Register for user authentication notifications
    [center addObserver:self
               selector:@selector(prepareMailWindow:)
                   name:HNUserAuthenticationDidChangeNotification
                 object:nil];

    [emailsHeaderView setDelegate:self];
    [[emailsHeaderView enclosingScrollView] setVerticalLineScroll:SMEmailTableViewRowHeightTraditionalView];
    [emailsHeaderView setAllowsColumnReordering:NO];
    [emailsHeaderView setAllowsColumnSelection:NO];
    [emailsHeaderView setAllowsMultipleSelection:YES];
    [emailsHeaderView registerForDraggedTypes:[tableTestDragType]];

    //[emailsHeaderView setUsesAlternatingRowBackgroundColors:YES];
    [theWindow makeFirstResponder:emailsHeaderView];
    //var selHightLightColor = [CPColor colorWithHexString:@"a7cdf0"];
    //[emailsHeaderView setSelectionHighlightColor:selHightLightColor];


    // Table View customization
    [emailsHeaderView setBackgroundColor:[CPColor whiteColor]];

    // Read/unread messages column
    var unreadDescriptor = [CPSortDescriptor sortDescriptorWithKey:@"is_read" ascending:YES];
    //var unread = [[CPTableColumn alloc] initWithIdentifier:@"SMUnreadTableColumn"];

    var unreadHeaderView = [unread headerView],
        unreadImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([unreadHeaderView bounds]), 13.0)];
    [unreadImageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_icon.png"] size:CGSizeMake(13, 13)]];
    [unreadImageView setAutoresizingMask:CPViewWidthSizable];
    [unreadImageView setImageScaling:CPScaleNone];
    [unreadHeaderView addSubview:unreadImageView];

    [testImageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_icon.png"] size:CGSizeMake(13, 13)]];

    [testImageView setImage:IsReadImage];

    [unread setSortDescriptorPrototype:unreadDescriptor];
    [unread setDataView:unreadImageView];

    // Subject column
    originalSubjectTableColumnWidth = [subjectTableColumn width];
    originalSubjectTableColumnView = [subjectTableColumn dataView];

    //var columnUnread  = [[emailsHeaderView tableColumns] objectAtIndex:0];
    var columnUID       = [[emailsHeaderView tableColumns] objectAtIndex:1],
        columnFrom      = [[emailsHeaderView tableColumns] objectAtIndex:2],
        columnSubject   = [[emailsHeaderView tableColumns] objectAtIndex:3],
        columnDate      = [[emailsHeaderView tableColumns] objectAtIndex:4];

    justSelect = NO;
    justSelectMailboxes = NO;

    [[columnUID headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"UID"]]
    [[columnFrom headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"From"]]
    [[columnSubject headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"Subject"]]
    [[columnDate headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"Date"]]

    //var emailsUnreadColumnView = [[EmailsUnreadColumnView alloc] initWithFrame:CGRectMake(0, 0, 22, 21)];
    //[columnUnread setDataView:emailsUnreadColumnView];

    // Toolbar customization
    var toolbarColor = [CPColor colorWithPatternImage:
                        [[CPImage alloc] initWithContentsOfFile:
                         [[CPBundle mainBundle] pathForResource:"toolbar_background_color.png"]
                                                           size:CGSizeMake(1, 59)]];

    if ([CPPlatform isBrowser])
        [[toolbar _toolbarView] setBackgroundColor:toolbarColor];

    [toolbar validateVisibleItems];

    // Give the email details header the same background colour as the source view.
    // TODO The details header view should have its own controller.
    [[fromLabel superview] setBackgroundColor:[CPColor colorWithHexString:@"D6DDE3"]];

    // Give the activity area the same background colour as the source view.
    // TODO The activity area should have its own controller.
    [[loadingLabel superview] setBackgroundColor:[CPColor colorWithHexString:@"FFFFFF"]];

    // Localize
    [fromLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"From"]]];
    [toLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"To"]]];
    [dateLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Date"]]];
    [subjectLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Subject"]]];

    // Reading pane initial view is parallel, but might have specified a different default.
    [self setDisplayedViewKey:[mailSplitView isVertical] ? @"ParallelView" : @"TraditionalView"];
}

- (void)prepareMailWindow:(id)sender
{
    var authenticationController = [HNAuthController sharedController];
    if ([authenticationController isAuthenticated])
    {
        [loadingLabel setObjectValue:@"Loading Mailboxes..."];
        /*alert("asdf1");
        imapServer = [[HNRemoteService alloc] initForScalaTrait:@"com.smartmobili.service.ImapService"
                                                   objjProtocol:nil
                                                       endPoint:nil
                                                       delegate:self];*/
        _serverConnection = [[ServerConnection alloc] init];

        [self setMailAccount:[SMMailAccount new]];
        [mailAccount load];

        // TODO: when COMET will be used perhaps _eventsFromServerReceiver should connect to server even before login? Or not.
        _eventsFromServerReceiver = [[EventsFromServerReceiver alloc]
                                     initWithAuthenticationController:authenticationController
                                     withDelegate:nil
                                     withEventOccurredSelector: nil
                                     withMailController:self];
        [_eventsFromServerReceiver start];
    }
    [self showWindow:sender];
}

- (void)showWindow:(id)sender
{
    var authenticationController = [HNAuthController sharedController];
    if ([authenticationController isAuthenticated])
    {
        [theWindow center];
        [theWindow makeKeyAndOrderFront:self];
    }
}

- (void)setMailAccount:(SMMailAccount)aMailAccount
{
    if (mailAccount)
    {
        [mailAccount removeObserver:self];
    }
    mailAccount = aMailAccount;
    [mailAccount setDelegate:self];
    [self addObserver:self forKeyPath:@"selectedMailbox.mailHeaders" options:nil context:nil];
    [self addObserver:self forKeyPath:@"mailAccount.mailboxes" options:nil context:nil];
}

- (void)setSelectedMailbox:(SMMailbox)aMailbox
{
    CPLog.trace(@"setSelectedMailbox : %@", aMailbox);
    selectedMailbox = aMailbox;

    if (!selectedMailbox)
        return;

    // get count of mails in folder and convert to pages count
    var pages = Math.floor([selectedMailbox count] / 50 + 1);
    [[self getPagerControlFromToolbar] setPages:pages];

    [self reLoadHeadersListForMailbox:aMailbox andPage:1];
}

- (void)reLoadHeadersListForMailbox:(SMMailbox)aMailbox andPage:(int)page
{
    [loadingLabel setObjectValue:[[CPString alloc] initWithFormat:@"Loading Headers for %@...", [aMailbox name]]];

    [[self getPagerControlFromToolbar] setPage:page];

    [emailsHeaderView deselectAll]; // TODO: perhaps need disable emails view or make it nonclickable etc.

    [aMailbox loadHeadersAtPage:page];
}

- (void)reload
{
    [webView reload:self];
}

- (CPString)sectionForAttachment:(CPArray)attachments
{
    // TODO: this shows attachemts as list of links, which not works. Need to show not links, but thumbnails or somethink like that.

    // Build the list of attachments
    var attachmentSection = @"";
    for (var i = 0; i < [attachments count]; i++)
    {
        attachmentSection = [attachmentSection stringByAppendingString:[CPString stringWithFormat:@"<div class=''><ul><li><a href='%@'>%@</a></li></ul></div>", [attachments objectAtIndex:i],[attachments objectAtIndex:i]]];
    }
    return attachmentSection;
}

#pragma mark -
#pragma mark SMMailAccount Delegate and Observation
- (void)mailAccountDidReload:(SMMailAccount)anAccount
{
    [loadingLabel setObjectValue:@"Mailboxes Loaded. Loading Headers for INBOX..."];
    selectedMailBox = nil;
    // The new selection will lead to a setSelectedMailboxName which in turn will finish loading
    // the box we want to see.
    [mailSourceController reloadAndSelectInbox];
}

- (void)observeValueForKeyPath:keyPath
    ofObject:anObject
    change:change
    context:context
{
    if (keyPath == @"selectedMailbox.mailHeaders")
    {
        [emailsHeaderView reloadData];
        if (!selectedMailbox)
            [loadingLabel setObjectValue:@"No Mailbox Selected."];
        else
        {

             [loadingLabel setObjectValue:@"Mail headers loaded"];
            // FIXME: The selected mail should be the most recent
            [emailsHeaderView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
    }
    else if (keyPath == @"mailAccount.mailboxes")
    {
        [mailSourceController reload];
    }
}

#pragma mark -
#pragma mark Actions
- (IBAction)composeMail:(id)sender
{
    _composeController = [[ComposeController alloc] init];
    [_composeController setMessageIdToOpenFromImap:nil andFolder:nil];

    var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Compose.cib"]];
    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:_composeController forKey:CPCibOwner]];

    /*var indexesSelectedEmail = emailsHeaderView._selectedRowIndexes;
    if ([indexesSelectedEmail count] == 1)
    {
        var row = [emailsHeaderView selectedRow],
            tblColumn = [emailsHeaderView tableColumnWithIdentifier:@"UID"],
            message_id = [self tableView:emailsHeaderView objectValueForTableColumn:tblColumn row:row];
        CPLog.trace(message_id);

        //
        _composeController = [[ComposeController alloc] init];
        var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Compose.cib"]];
        [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:_composeController forKey:CPCibOwner]];
    }*/
}

- (void)setDisplayedViewKey:(CPString)viewOption
{
    displayedViewKey = viewOption;

    // Find the toolbar item to update to reflect the new choice, and the menu options.
    var toolbarItems = [toolbar items],
        theSwitcher,
        viewMenu = [[[CPApplication sharedApplication] mainMenu] itemWithTag: @"SMViewMenu"],
        readingPaneMenu = [[viewMenu submenu] itemWithTag:@"SMReadingPaneMenu"],
        rightMenuItem = [[readingPaneMenu submenu] itemWithTag:@"ParallelView"],
        belowMenuItem = [[readingPaneMenu submenu] itemWithTag:@"TraditionalView"];

    for (var i = 0; i < [toolbarItems count]; i++)
    {
        if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus")
            theSwitcher = [[toolbarItems objectAtIndex:i] view];
    }

    [theSwitcher selectSegmentWithTag:displayedViewKey];
    [theSwitcher setImage:(displayedViewKey == @"TraditionalView" ? SwitcherTraditionalViewOnImage : SwitcherTraditionalViewOffImage) forSegment:0];
    [theSwitcher setImage:(displayedViewKey == @"ParallelView" ? SwitcherParallelViewOnImage : SwitcherParallelViewOffImage) forSegment:1];


    // Update the UI to reflect the new selection.
    if (displayedViewKey == @"ParallelView")
    {
        [belowMenuItem setState:CPOffState];
        [rightMenuItem setState:CPOnState];
    }
    else
    {
        [belowMenuItem setState:CPOnState];
        [rightMenuItem setState:CPOffState];
    }

    switch (displayedViewKey)
    {
        case @"ParallelView":
            [subjectTableColumn setWidth:SMSubjectTableColumnWidthParallelView];
            [emailsHeaderView setRowHeight:SMEmailTableViewRowHeightParallelView];
            [fromTableColumn setHidden:YES];
            [dateTableColumn setHidden:YES];
            [mailSplitView setVertical:YES];
            break;
        case @"TraditionalView":
        default:
            [mailSplitView setVertical:NO];

            [fromTableColumn setHidden:NO];
            [dateTableColumn setHidden:NO];

            // Force the data views to load to avoid a bug in Cappuccino 0.9.5 where calling setWidth:
            // on a column causes the table to try to touch not yet existing layout data for previously
            // hidden columns.
            [emailsHeaderView load];
            [subjectTableColumn setWidth:originalSubjectTableColumnWidth];
            [emailsHeaderView setRowHeight:SMEmailTableViewRowHeightTraditionalView];
            // Force complete redraw to avoid a bug in Cappuccino 0.9.5 where changing the row height
            // causes incorrect drawing.
            [emailsHeaderView reloadData];
            break;
    }
}

- (IBAction)switchMailOrientation:(id)sender
{
    // By default select the tag
    var viewOption = [sender tag];

    // If the message is sent by the bar switcher,
    // then the selected tag is needed
    if (viewOption == @"changeViewStatus")
        viewOption = [sender selectedTag];

    [self setDisplayedViewKey:viewOption];
}

#pragma mark -
#pragma mark Toolbar Delegate

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, "searchField", "composeMail", "refreshMailbox", "deleteMail", "replyMail", "pagerControl", "switchViewStatus", "logo"];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    var items = [ CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, "composeMail", "refreshMailbox", "deleteMail", "replyMail", CPToolbarFlexibleSpaceItemIdentifier, "searchField", CPToolbarFlexibleSpaceItemIdentifier, "pagerControl", "switchViewStatus"];

    if ([CPPlatform isBrowser])
        items.unshift("logo");

    return items;
}


- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var mainBundle = [CPBundle mainBundle],
        toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    [toolbarItem setVisibilityPriority:CPToolbarItemVisibilityPriorityUser];

    switch (itemIdentifier)
    {
        case @"logo":
//            [toolbarItem setView:logoView];
//            [toolbarItem setMinSize:CGSizeMake(200, 32)];
//            [toolbarItem setMaxSize:CGSizeMake(200, 32)];
//
//            //FIXME this should be possible without this
//            window.setTimeout(function(){
//                var toolbarView = [toolbar _toolbarView],
//                superview = [[toolbar items][0] view]; //FIXME
//
//                while (superview && superview !== toolbarView)
//                {
//                    [superview setClipsToBounds:NO];
//                    superview = [superview superview];
//                }
//            }, 0);
            break;

        case @"searchField":
            var searchField = [[ToolbarSearchField alloc] initWithFrame:CGRectMake(0,0, 240, 30)];

            [searchField setTarget:self];
            [searchField setAction:@selector(searchFieldDidChange:)];
            [searchField setSendsSearchStringImmediately:YES];
            [searchField setPlaceholderString:"Search Mail"];

            [toolbarItem setLabel:[[TNLocalizationCenter defaultCenter] localize:@"Search Mail"]];
            [toolbarItem setView:searchField];
            [toolbarItem setTag:@"SearchMail"];

            [toolbarItem setMinSize:CGSizeMake([CPPlatform isBrowser] ? 240 : 220, 30)];
            [toolbarItem setMaxSize:CGSizeMake([CPPlatform isBrowser] ? 240 : 220, 30)];

            [self addCustomSearchFieldAttributes:searchField];
            break;

        case @"pagerControl":
            var pager = [[SMPagerView alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];

            [toolbarItem setView:pager];

            [toolbarItem setMinSize:CGSizeMake(120, 30)];
            [toolbarItem setMaxSize:CGSizeMake(120, 30)];

            [toolbarItem setTag:@"pagerControl"];
            [toolbarItem setLabel:[CPString stringWithFormat:@"%@", [[TNLocalizationCenter defaultCenter] localize:@"Page"]]];
            break;
        case @"switchViewStatus":
            var aSwitch = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,0,0,0)];

            [aSwitch setTrackingMode:CPSegmentSwitchTrackingSelectOne];
            [aSwitch setTarget:self];
            [aSwitch setAction:@selector(switchMailOrientation:)];
            [aSwitch setSegmentCount:2];
            [aSwitch setWidth:[CPPlatform isBrowser] ? 65 : 80 forSegment:0];
            [aSwitch setWidth:[CPPlatform isBrowser] ? 65 : 80 forSegment:1];
            [aSwitch setTag:@"TraditionalView" forSegment:0];
            [aSwitch setTag:@"ParallelView" forSegment:1];
            [aSwitch selectSegmentWithTag:displayedViewKey];

            [aSwitch setImage:(displayedViewKey == @"TraditionalView" ? SwitcherTraditionalViewOnImage : SwitcherTraditionalViewOffImage) forSegment:0];
            [aSwitch setImage:(displayedViewKey == @"ParallelView" ? SwitcherParallelViewOnImage : SwitcherParallelViewOffImage) forSegment:1];

            [toolbarItem setView:aSwitch];
            [toolbarItem setTag:@"changeViewStatus"];
            [toolbarItem setLabel:[CPString stringWithFormat:@"%@", [[TNLocalizationCenter defaultCenter] localize:@"Pane Orientation"]]];

            [toolbarItem setMinSize:CGSizeMake([CPPlatform isBrowser] ? 130 : 160, 24)];
            [toolbarItem setMaxSize:CGSizeMake([CPPlatform isBrowser] ? 130 : 160, 24)];

            [self addCustomSegmentedAttributes:aSwitch];
            break;

        case @"composeMail":
            [self prepareToolbarItem:toolbarItem itemIdentifier:itemIdentifier];
            [toolbarItem setEnabled:YES];
            break;
        case @"refreshMailbox":
            [self prepareToolbarItem:toolbarItem itemIdentifier:itemIdentifier];
            [toolbarItem setEnabled:YES];
            break;
        case @"deleteMail":
            [self prepareToolbarItem:toolbarItem itemIdentifier:itemIdentifier];
            [toolbarItem setEnabled:NO];
            break;
        case @"replyMail":
            [self prepareToolbarItem:toolbarItem itemIdentifier:itemIdentifier];
            [toolbarItem setEnabled:NO];
            break;

    }
    return toolbarItem;
}

- (void)prepareToolbarItem:(CPToolbarItem)toolbarItem itemIdentifier:(CPString)itemIdentifier
{
    var mainBundle = [CPBundle mainBundle],
        iconPath = [[CPString alloc] initWithFormat:@"Icons/%@.png", [itemIdentifier lowercaseString]],
        image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:iconPath] size:CPSizeMake(24, 24)];
    [toolbarItem setImage:image];
    [toolbarItem setAlternateImage:image];
    [toolbarItem setTarget:self];
    var selector = CPSelectorFromString([CPString stringWithFormat:@"%@:", itemIdentifier]);
    [toolbarItem setAction:selector];
    [toolbarItem setLabel:[[TNLocalizationCenter defaultCenter] localize:itemIdentifier]];
    [toolbarItem setMinSize:CGSizeMake(32, 32)];
    [toolbarItem setMaxSize:CGSizeMake(32, 32)];

}

- (void)deleteMail:(id)sender
{
    CPLog.debug(@"%@", _cmd);
}

- (void)replyMail:(id)sender
{
    CPLog.debug(@"%@", _cmd);
}

- (void)refreshMailbox:(id)sender
{
    /* disabled during porting from scala to java. Because now No cardano/lift autoupdated objects anymore, so after refresh
     objects at server we need also realod screen or something like that).
     *
    CPLog.debug(@"%@", _cmd);
    [imapServer synchronizeAll:@""
                      delegate:nil
                         error:nil];*/
    alert("Refresh function is not yet implemented");
}

- (CPToolbarItem)getToolBarItemViaIdentifier:(CPString)toolbarItemIdentifier
{
    var toolbarItems = [toolbar items];
    for (var i = 0; i < [toolbarItems count]; i++)
    {
        var item = [toolbarItems objectAtIndex:i];
        if ([item itemIdentifier] == toolbarItemIdentifier)
            return item;
    }
    return nil;
}

- (SMPagerView)getPagerControlFromToolbar
{
    var toolbarItem = [self getToolBarItemViaIdentifier:@"pagerControl"],
        smPagerView = toolbarItem._view;
    return smPagerView;
}

- (void)toolbarItemPagerControlChangedValue
{
    var page = [[self getPagerControlFromToolbar] getPage];

    [self reLoadHeadersListForMailbox:selectedMailbox andPage:page];
}

#pragma mark -
#pragma mark TableView Delegate
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{

    CPLog.trace(@"CPTableView -  menuForTableColumn : row =%d", aRow );

    /* Contextual menu for email */
    var emailContextMenu = [[CPMenu alloc] init];

    //var newItem = [[CPMenuItem alloc] initWithTitle:@"Open Message" action:@selector(openMessage:) keyEquivalent:@""];
    //[newItem setImage:[[NSImage imageNamed:@"wall"] retain]];
    //[newItem setTarget:self];
    //[newItem setTag:TILE_WALL];
    //[emailContextMenu addItem:newItem];

    [[emailContextMenu addItemWithTitle:@"Open Message" action:@selector(openMessage:) keyEquivalent:nil] setTarget:self];
    [emailContextMenu addItem:[CPMenuItem separatorItem]];
    [[emailContextMenu addItemWithTitle:@"Reply" action:nil keyEquivalent:nil] setTarget:self];
    [[emailContextMenu addItemWithTitle:@"Reply All" action:nil keyEquivalent:nil] setTarget:self];
    [[emailContextMenu addItemWithTitle:@"Forward" action:nil keyEquivalent:nil] setTarget:self];
    [[emailContextMenu addItemWithTitle:@"Mark as Read" action:nil keyEquivalent:nil] setTarget:self];
    [[emailContextMenu addItemWithTitle:@"Mark as Unread" action:nil keyEquivalent:nil] setTarget:self];
    [[emailContextMenu addItemWithTitle:@"Delete" action:@selector(deleteMessages:) keyEquivalent:nil] setTarget:self];

    return emailContextMenu;
}

- (IBAction)deleteMessages:(id)sender
{
    CPLog.trace(@"deleteMessages");

    //var row = [emailsHeaderView selectedRow];
    var messageIds = [CPMutableArray array];
	var folderName = [self.selectedMailbox name]
	
	var indexes = [];
	[[emailsHeaderView selectedRowIndexes] getIndexes:indexes maxCount:-1 inIndexRange:nil]
    
	for (var j=0; j<[indexes count]; j++)
    {
	    var msgId = [[[selectedMailbox mailHeaders] objectAtIndex:indexes[j]] messageId]
		[messageIds addObject:msgId];
    }

    [_serverConnection callRemoteFunction:@"deleteMessages"
                   withFunctionParametersAsObject:{ "messageIds":messageIds, "srcFolder":folderName }
                                         delegate:self
                                   didEndSelector:@selector(imapServerMessagesDeleted:withParametersObject:)
                                            error:nil]


}

- (void)imapServerMessagesDeleted:(id)sender withParametersObject:parametersObject
{
	CPLog.trace(@"imapServerMessagesDeleted");
	[mailSourceController reload];
}


- (IBAction)openMessage:(id)sender
{
    CPLog.trace(@"openMessage");

    _composeController = [[ComposeController alloc] init];

    var row = [emailsHeaderView selectedRow];
//    selectedEmail = [[[selectedMailbox mailHeaders] objectAtIndex:row] md5];
//    [loadingLabel setObjectValue:@"Loading E-mail Selected..."];
    var msgIdToOpen = [[[selectedMailbox mailHeaders] objectAtIndex:row] messageId],
        folderName = [self.selectedMailbox name];

    [_composeController setMessageIdToOpenFromImap:msgIdToOpen andFolder:folderName];

    var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Compose.cib"]];
    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:_composeController forKey:CPCibOwner]];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [[selectedMailbox mailHeaders] count];
}
- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var result = nil,
        mailHeaders = [selectedMailbox mailHeaders];

    if (mailHeaders)
    {
        //CPLog.trace([mailHeaders objectAtIndex:aRow].MessageId);
        if ([[aTableColumn identifier] isEqualToString:@"UID"])
        {
            result = [[mailHeaders objectAtIndex:aRow] messageId];
        }
        else if ([[aTableColumn identifier] isEqualToString:@"From"])
        {
            //CPLog.debug(@"Mail headers %@", [mailHeaders objectAtIndex:aRow]);
            result = [[mailHeaders objectAtIndex:aRow] fromName];
            if (result.length == 0)
                result = [[mailHeaders objectAtIndex:aRow] fromEmail];
        }
        else if ([[aTableColumn identifier] isEqualToString:@"Subject"])
        {
            var toolbarItems = [toolbar items],
                viewSelected;
            for (var i = 0; i < [toolbarItems count]; i++)
            {
                if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus")
                {
                    viewSelected = [[[toolbarItems objectAtIndex:i] view] selectedTag];
                }
            }
            switch (viewSelected)
            {
                case @"TraditionalView":
                    result = [[mailHeaders objectAtIndex:aRow] subject];
                    break;
                case @"ParallelView":
                    var email = [SMEmail new];
                    [email setFrom:[[mailHeaders objectAtIndex:aRow] fromEmail]];
                    [email setSubject:[[mailHeaders objectAtIndex:aRow] subject]];
                   // var dte = [[mailHeaders objectAtIndex:aRow] date]; // CPDate
                    var dte = nil,
                        mh = [mailHeaders objectAtIndex:aRow];
                    if (mh.dateExists == true)
                    {
                        dte = [[[mailHeaders objectAtIndex:aRow] date] formattedDescription];
                    }
                    else
                    {
                        dte = "No Date"; // TODO: add localization
                    }

                    [email setDate:dte]; // where is this used?
                    result = email;
                    break;
                default:
                    break;
            }
        }
        else if ([aTableColumn._identifier isEqualToString:@"Date"])
        {
            var mh = [mailHeaders objectAtIndex:aRow];
            if (mh.dateExists == true)
            {
                result = [[[mailHeaders objectAtIndex:aRow] date] formattedDescription];
            }
            else
            {
                result = "No Date"; // TODO: add localization
            }
        }
        else if ([[aTableColumn identifier] isEqualToString:@"SMUnreadTableColumn"])
        {
            result = [[mailHeaders objectAtIndex:aRow] isSeen] ? nil : IsReadImage;
        }
    }

    return result;
}


- (void)imapServerMailContentDidReceived:(id)sender withParametersObject:parametersObject
{
    //CPLog.debug(@"%@%@", _cmd, mailContent);
    //if ([mailContent respondsToSelector:@selector(body)])
    if (parametersObject.mailContent)
    {
        [toContent setObjectValue:parametersObject.mailContent.to];

        if (parametersObject.mailContent.sentDate > 0) // if sentdate = "" (string) means no date there. If sentdate is number greater than 0 this means that there is valid date.
        {
            var sd = parametersObject.mailContent.sentDate,
                date = [[CPDate alloc] initWithTimeIntervalSince1970:sd];
            [dateContent setObjectValue:[date formattedDescription]];
        }
        else
        {
            [dateContent setObjectValue:@"No Date"]; // TODO: use localization
        }

        [fromContent setObjectValue:parametersObject.mailContent.from];
        [subjectContent setObjectValue:parametersObject.mailContent.subject];

        var attachment = ""; // TODO: there was used sectionForAttachment function but this way is not good (it just show not working links to attachments). In this way it was used: [self sectionForAttachment:[mailContent attachment]]
        // Build the whole message
        [webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><head></head><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@%@</body></html>", parametersObject.mailContent.body, attachment]];
        [loadingLabel setObjectValue:@"Mail Content Loaded."];

        // Issue #4
        // Maybe related to loadHTMLString subtleties,
        // it should be avoided with the next CPWebView
        // subclass implementation
        window.setTimeout(function() {
            [self reload];
        }, 0);
    } else {
        [loadingLabel setObjectValue:@"Error fetching the email."];
    }
}

- (CPView)tableView:(CPTableView)tableView dataViewForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    // Select the switch view in the toolbar
    // in order to know the orientation selected
    var toolbarItems = [toolbar items],
        viewSelected;
    for (var i = 0; i < [toolbarItems count]; i++)
    {
        if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus")
        {
            viewSelected = [[[toolbarItems objectAtIndex:i] view] selectedTag];
        }
    }

    var newDataView = [tableColumn dataView];
    if ([[tableColumn identifier] isEqualToString:@"Subject"])
    {
        switch (viewSelected)
        {
            case @"TraditionalView":
                newDataView = originalSubjectTableColumnView;
                break;
            case @"ParallelView":
                newDataView = parallelDataView;
                break;
            default:
                break;
        }
    }
    return newDataView;
}

- (IBAction)refresh:(id)sender
{
    CPLog.info(@"Refresh...");
}

- (void)clearMailContent
{
    [toContent setObjectValue:@""];
    [dateContent setObjectValue:@""];
    [fromContent setObjectValue:@""];
    [subjectContent setObjectValue:@""];
    [webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><body>%@</body></html>", @""]];
}

// The tableview will call this method if you click the tableheader. You should sort the datasource based off of the new sort descriptors and reload the data
/*
- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors {
    var descriptor = [aTableView._sortDescriptors objectAtIndex:0];
    [mailHeaders sortUsingDescriptors:[descriptor]];
}
*/

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    // If i just want to select, and not reload
    if (justSelect)
    {
        justSelect = NO;
        return;
    }
    if ([aNotification object] == emailsHeaderView)
    {
        // Get the Delete and the Reply CPToolbarItem
        deleteItem = [toolbar._items objectAtIndex:3];// TODO: make getting using getToobarItemViaIDentifier function in this class.
        replyItem = [toolbar._items objectAtIndex:4];

        // User selected one/another e-mail
        var indexesSelectedEmail = [emailsHeaderView selectedRowIndexes],
            mailHeaders = [selectedMailbox mailHeaders];

        if ([indexesSelectedEmail count] == 1)
        {
            selectedEmail = [[mailHeaders objectAtIndex:[indexesSelectedEmail firstIndex]] messageId];
            [loadingLabel setObjectValue:@"Loading E-mail Selected..."];

            var selectedMailboxName = [selectedMailbox name] || @"Inbox";


            // (This is old todo) TODO We should use an SMEmail (with only headers) and have it load its own data here.
            // That way the results are cached, and the flow simpler.
            [_serverConnection callRemoteFunction:@"mailContentForMessageId"
                   withFunctionParametersAsObject:{ "messageId":selectedEmail, "folder":selectedMailboxName }
                                         delegate:self
                                   didEndSelector:@selector(imapServerMailContentDidReceived:withParametersObject:)
                                            error:nil];

            // Both Active
            [deleteItem setEnabled:YES];
            [replyItem setEnabled:YES];
        }
        else
        {
            // Deselected E-mail
            selectedEmail = nil;
            [self clearMailContent];
            if ([indexesSelectedEmail count] == 0)
            {
 // TODO: add this if need later, but it overlap "Headers load event status"               [loadingLabel setObjectValue:@"None E-mail selected."];
                // None Active
                [deleteItem setEnabled:NO];
                [replyItem setEnabled:NO];
            }
            else
            {
                [loadingLabel setObjectValue:@"Multiple E-mails selected."];
                // Only Delete active
                [deleteItem setEnabled:YES];
                [replyItem setEnabled:NO];
            }
        }
    }
}

#pragma mark -
#pragma mark Menu Item Validation
- (@action)selectAll:(id)sender
{
    var range = CPMakeRange(0, [emailsHeaderView numberOfRows]),
        indexes = [CPIndexSet indexSetWithIndexesInRange:range];
    [emailsHeaderView selectRowIndexes:indexes byExtendingSelection:NO];
}

- (BOOL)shouldSelectAll
{
    // Eventually we could implement code here
    // to determine if we want selection
    // when other view -different to table view-
    // is focused. In the meanwhile, returning YES
    // means that the table view is selectable
    // whatever other view is in focus.
    return YES;
}

// FIXME: to App Controller
- (void)addCustomSegmentedAttributes:(CPSegmentedControl)aControl
{
    var dividerColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"display-mode-divider.png"] size:CGSizeMake(1, 24)]],
        leftBezel = PatternColor(MainBundleImage("display-mode-left-bezel.png", CGSizeMake(4, 24))),
        centerBezel = PatternColor(MainBundleImage("display-mode-center-bezel.png", CGSizeMake(1, 24))),
        rightBezel = PatternColor(MainBundleImage("display-mode-right-bezel.png", CGSizeMake(4, 24))),
        leftBezelHighlighted = PatternColor(MainBundleImage("display-mode-left-bezel-highlighted.png", CGSizeMake(4, 24))),
        centerBezelHighlighted = PatternColor(MainBundleImage("display-mode-center-bezel-highlighted.png", CGSizeMake(1, 24))),
        rightBezelHighlighted = PatternColor(MainBundleImage("display-mode-right-bezel-highlighted.png", CGSizeMake(4, 24))),
        leftBezelSelected = PatternColor(MainBundleImage("display-mode-left-bezel-selected.png", CGSizeMake(4, 24))),
        centerBezelSelected = PatternColor(MainBundleImage("display-mode-center-bezel-selected.png", CGSizeMake(1, 24))),
        rightBezelSelected = PatternColor(MainBundleImage("display-mode-right-bezel-selected.png", CGSizeMake(4, 24))),
        leftBezelDisabled = PatternColor(MainBundleImage("display-mode-left-bezel-disabled.png", CGSizeMake(4, 24))),
        centerBezelDisabled = PatternColor(MainBundleImage("display-mode-center-bezel-disabled.png", CGSizeMake(1, 24))),
        rightBezelDisabled = PatternColor(MainBundleImage("display-mode-right-bezel-disabled.png", CGSizeMake(4, 24))),
        leftBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-left-bezel-selected-disabled.png", CGSizeMake(4, 24))),
        centerBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-center-bezel-selected-disabled.png", CGSizeMake(1, 24))),
        rightBezelSelectedDisabled = PatternColor(MainBundleImage("display-mode-right-bezel-selected-disabled.png", CGSizeMake(4, 24)));

    [aControl setValue:centerBezel forThemeAttribute:"center-segment-bezel-color"];
    [aControl setValue:centerBezelHighlighted forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:centerBezelSelected forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:centerBezelDisabled forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:centerBezelSelectedDisabled forThemeAttribute:"center-segment-bezel-color" inState:CPThemeStateSelected | CPThemeStateDisabled];

    [aControl setValue:leftBezel forThemeAttribute:"left-segment-bezel-color"];
    [aControl setValue:leftBezelHighlighted forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:leftBezelSelected forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:leftBezelDisabled forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:leftBezelSelectedDisabled forThemeAttribute:"left-segment-bezel-color" inState:CPThemeStateSelected | CPThemeStateDisabled];

    [aControl setValue:rightBezel forThemeAttribute:"right-segment-bezel-color"];
    [aControl setValue:rightBezelHighlighted forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateHighlighted];
    [aControl setValue:rightBezelSelected forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateSelected];
    [aControl setValue:rightBezelDisabled forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateDisabled];
    [aControl setValue:rightBezelSelectedDisabled forThemeAttribute:"right-segment-bezel-color" inState:CPThemeStateSelected | CPThemeStateDisabled];

    [aControl setValue:dividerColor forThemeAttribute:@"divider-bezel-color"];

    [aControl setValue:[CPColor colorWithCalibratedWhite:73.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [aControl setValue:[CPColor colorWithCalibratedWhite:96.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:222.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [aControl setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [aControl setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
}

// FIXME: to App Controller
- (void)addCustomSearchFieldAttributes:(CPSearchField)textfield
{
    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
                                   [
                                    MainBundleImage("searchfield-left-bezel.png", CGSizeMake(23.0, 24.0)),
                                    MainBundleImage("searchfield-center-bezel.png", CGSizeMake(1.0, 24.0)),
                                    MainBundleImage("searchfield-right-bezel.png", CGSizeMake(14.0, 24.0))
                                    ] isVertical:NO]),
        bezelFocusedColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
                                    [
                                       MainBundleImage("searchfield-left-bezel-selected.png", CGSizeMake(27.0, 30.0)),
                                       MainBundleImage("searchfield-center-bezel-selected.png", CGSizeMake(1.0, 30.0)),
                                       MainBundleImage("searchfield-right-bezel-selected.png", CGSizeMake(17.0, 30.0))
                                       ] isVertical:NO]);

    [textfield setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded];
    [textfield setValue:bezelFocusedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded | CPThemeStateEditing];

    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font"];
    [textfield setValue:CGInsetMake(10.0, 14.0, 6.0, 14.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded];

    [textfield setValue:CGInsetMake(3.0, 3.0, 3.0, 3.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded | CPThemeStateEditing];
    [textfield setValue:CGInsetMake(9.0, 14.0, 6.0, 14.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded | CPThemeStateEditing];
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                   validateDrop:(id)info
                   proposedRow:(CPInteger)row
                   proposedDropOperation:(CPTableViewDropOperation)operation
{
    CPLog.trace(@"aTableView.validateDrop : row=%d", row);
    [aTableView setDropRow:(row) dropOperation:CPTableViewDropOn];

    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{
    CPLog.trace(@"aTableView.acceptDrop : row=%d", row);
    return YES;
}


#pragma mark -
#pragma mark CPSplitView delegate

/*!
    Don't allocate more width than what is useful to the left hand side of the parallel mode headers/mail split
    view.
*/
- (void)splitView:(CPSplitView)sender resizeSubviewsWithOldSize:(CGSize)oldSize
{
    var newFrame = [sender frame],
        newWidth = newFrame.size.width,
        oldWidth = oldSize.width,
        left = nil;

    if (newWidth > oldWidth && sender == mailSplitView && displayedViewKey == @"ParallelView")
    {
        left = [sender subviews][0];

        // Figure out the amount of space the header table needs to show all its columns fully.
        var tableColumns = [emailsHeaderView tableColumns],
            rightMostVisibleColumnIndex = [tableColumns count] - 1;

        while (rightMostVisibleColumnIndex > 0 && [[tableColumns objectAtIndex:rightMostVisibleColumnIndex] isHidden])
            rightMostVisibleColumnIndex--;

        var totalColumnWidth = CGRectGetMaxX([emailsHeaderView rectOfColumn:rightMostVisibleColumnIndex]),
            scrollView = [emailsHeaderView enclosingScrollView],
            scrollerFrameWidth = [scrollView frame].size.width - [scrollView contentSize].width,
            leftFrame = [left frame],
            leftWidth = leftFrame.size.width,
            newLeftWidth = leftWidth + (newWidth - oldWidth) / 2.0;

        // XXX ATM the subject column auto resizes which mostly negates the purpose of all this code (there
        // can be no empty space on the right if the column automatically takes up all that space.) To prevent
        // us from only ever shrinking the subject column and not allowing it to grow back to its regular size
        // when the window is made larger again, we extent totalColumnWidth to our "desired" width rather than
        // the actual.
        if ([subjectTableColumn width] < SMSubjectTableColumnWidthParallelView)
            totalColumnWidth += 4 + SMSubjectTableColumnWidthParallelView - [subjectTableColumn width];

        // If we just resize uniformly, will the new size be wider than what we need?
        if (newLeftWidth > totalColumnWidth + scrollerFrameWidth)
        {
            // Yes it will. Just max out the left view and give the rest to the right hand side.
            var right = [sender subviews][1],
                rightFrame = [right frame],
                dividerThickness = [sender dividerThickness];

            // Update the subview frames so that any change in width is applied to the right hand side.
            leftFrame.size.height = newFrame.size.height;
            rightFrame.size.height = newFrame.size.height;

            leftFrame.origin = CGPointMake(0, 0);
            leftFrame.size.width = totalColumnWidth + scrollerFrameWidth;
            rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
            rightFrame.origin.x = leftFrame.size.width + dividerThickness;
            [left setFrame:leftFrame];
            [right setFrame:rightFrame];

            return;
        }
    }

    // Call the normal resizing code.
    [sender setDelegate:nil];
    [sender resizeSubviewsWithOldSize:oldSize];
    [sender setDelegate:self];
}

#pragma mark -
#pragma mark Other

- (void)setErrorInConnectionFloatingWindowVisible:(bool)visible
{
    if (visible == true)
    {
        if (!_connectionErrorWholeScreenWindow)
        {
            // This is invisible window in whole screen, to avoid user clicking on components of main app while connections is lost.
            _connectionErrorWholeScreenWindow = [[CPWindow alloc]
                     initWithContentRect:CGRectMakeZero()
                     styleMask:CPBorderlessBridgeWindowMask],
            contentView = [_connectionErrorWholeScreenWindow contentView];

            [_connectionErrorWholeScreenWindow orderFront:self];

            //  [contentView setBackgroundColor:[CPColor blackColor]];

            _connectionErrorFloatingWindow = [[CPPanel alloc]
                    initWithContentRect:CGRectMake(0, 0, 225, 50)
                    styleMask:CPHUDBackgroundWindowMask];

            [_connectionErrorFloatingWindow setFloatingPanel:NO];

            [_connectionErrorFloatingWindow orderFront:self];

            [_connectionErrorFloatingWindow setTitle:"Connection error"];
            [_connectionErrorFloatingWindow center];

            var panelContentView = [_connectionErrorFloatingWindow contentView],
                scaleStartLabel = [CPTextField labelWithTitle:"Trying to reconnect..."];
            // TODO: perhaps add seconds counting (or connections trying count) to show user that it really trying. Also ajax-loader icon will be usefull.
            [scaleStartLabel setFrameOrigin:CGPointMake(45, 10)];
            [scaleStartLabel setTextColor:[CPColor grayColor]];

            [scaleStartLabel sizeToFit];
            [panelContentView addSubview:scaleStartLabel];
        }
        else
        {
             if ([_connectionErrorWholeScreenWindow isVisible] == false)
             {
                 [_connectionErrorWholeScreenWindow orderFront:self];
                 [_connectionErrorFloatingWindow orderFront:self];
             }
        }
    }
    else
    {
        if (_connectionErrorWholeScreenWindow)
        {
            if ([_connectionErrorWholeScreenWindow isVisible])
            {
                [_connectionErrorWholeScreenWindow close];
                [_connectionErrorFloatingWindow close];
            }
        }
    }
}

@end

@implementation ToolbarSearchField : CPSearchField
{
}

- (void)resetSearchButton
{
    [super resetSearchButton];
    [[self searchButton] setImage:nil];
}

@end

function MainBundleImage(path, size)
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:path] size:size];
}

function PatternColor(anImage)
{
    return [CPColor colorWithPatternImage:anImage];
}
