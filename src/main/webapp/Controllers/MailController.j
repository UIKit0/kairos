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
@import "../Models/Imap.j"
@import "../Models/SMEmail.j"
@import "../Models/Email.j"
@import "../Models/SMEmailService.j"
@import "../Models/SMMailbox.j"
@import "../Models/SMMailHeader.j"
@import "../Models/SMMailContent.j"
@import "../Views/SMEmailSubjectView.j"
@import "../Controllers/HNAuthController.j"

SMOutlineViewMailPaneMinimumSize = 230; // 198
SMOutlineViewMailPaneMaximumSize = 400; 
SMEmailTableViewRowHeightParallelView = 40;
SMEmailTableViewRowHeightTraditionalView = 23;
SMSubjectTableColumnWidthParallelView = 440;

@implementation MailController : CPWindowController 
{
	@outlet CPScrollViewEx scrollViewEmails;
	
    @outlet CPWindow		theWindow @accessors;
	@outlet CPToolbar		toolbar;
	@outlet CPScrollView	mailboxesScrollview;
	@outlet CPTextField		loadingLabel;
	@outlet CPWebView		webView;
	@outlet CPTextField		fromContent;
	@outlet CPTextField		toContent;
	@outlet CPTextField		dateContent;
	@outlet CPTextField		subjectContent;
	@outlet CPTextField		fromLabel;
	@outlet CPTextField		toLabel;
	@outlet CPTextField		dateLabel;
	@outlet CPTextField		subjectLabel;
	@outlet CPSplitView		mailSplitView;
	@outlet CPTableView     emailsHeaderView;
    
    IBOutlet SMEmailSubjectView parallelDataView;
    IBOutlet CPTableColumn  unread;
    IBOutlet CPTableColumn  fromTableColumn;
    IBOutlet CPTableColumn  subjectTableColumn;
    IBOutlet CPTableColumn  dateTableColumn;

    CPView originalSubjectTableColumnView;
    int originalSubjectTableColumnWidth;
    
    IBOutlet CPImageView    testImageView;

    
    CPImage                 cachedIsReadImage;
    CPImage                 cachedSwitcherTraditionalViewOnImage;
    CPImage                 cachedSwitcherTraditionalViewOffImage;
    CPImage                 cachedSwitcherParallelViewOnImage;
    CPImage                 cachedSwitcherParallelViewOffImage;
	
	
	ComposeController		_composeController;
	CPOutlineView			mailboxesTableView;
	
    
    // Cardano
    HNRemoteService         imapServer;
    CPArray                 mailboxes;
    CPArray                 mailboxesOthers;
    CPDictionary            mailboxesTree;
    SMMailbox               mailboxesHeader;
    SMMailbox               othersHeader
    CPArray                 mailHeaders;
    
    
	Imap					imap;
	CPString				selectedMailBox;
	CPString				selectedEmail;
	BOOL					justSelect;
	BOOL					justSelectMailboxes;
    CPDictionary			items;
    
    // This should be moved to the App Controller
	CPString                displayedViewKey @accessors;
    @outlet CPView          logoView;
	
}

#pragma mark ViewControler cyle
- (void)awakeFromCib 
{
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
	[emailsHeaderView setUsesAlternatingRowBackgroundColors:YES];
    [theWindow makeFirstResponder:emailsHeaderView];
	//var selHightLightColor = [CPColor colorWithHexString:@"a7cdf0"];
	//[emailsHeaderView setSelectionHighlightColor:selHightLightColor];
	
    
    // Table View customization
    [emailsHeaderView setBackgroundColor:[CPColor whiteColor]];
    
    // Read/unread messages column
    var unreadDescriptor = [CPSortDescriptor sortDescriptorWithKey:@"is_read" ascending:YES];
    //var unread = [[CPTableColumn alloc] initWithIdentifier:@"SMUnreadTableColumn"];

    var unreadHeaderView = [unread headerView];
    var unreadImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([unreadHeaderView bounds], 13))];
    [unreadImageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_icon.png"] size:CGSizeMake(13, 13)]];
    [unreadImageView setAutoresizingMask:CPViewWidthSizable];
    [unreadImageView setImageScaling:CPScaleNone];
    [unreadHeaderView addSubview:unreadImageView];
    
    [testImageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_icon.png"] size:CGSizeMake(13, 13)]];
    cachedIsReadImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"unread_marker.png"] size:CGSizeMake(11, 12)];

    [testImageView setImage:cachedIsReadImage];
    
    [unread setSortDescriptorPrototype:unreadDescriptor];
    [unread setDataView:unreadImageView];
    
    // Subject column
    originalSubjectTableColumnWidth = [subjectTableColumn width];
    originalSubjectTableColumnView = [subjectTableColumn dataView];
    
	//var columnUnread	= [[emailsHeaderView tableColumns] objectAtIndex:0];
	var columnUID		= [[emailsHeaderView tableColumns] objectAtIndex:1];
	var columnFrom		= [[emailsHeaderView tableColumns] objectAtIndex:2];
	var columnSubject	= [[emailsHeaderView tableColumns] objectAtIndex:3];
	var columnDate		= [[emailsHeaderView tableColumns] objectAtIndex:4];

	justSelect = NO;
	justSelectMailboxes = NO;
	
	[[columnUID headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"UID"]]
	[[columnFrom headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"From"]]
	[[columnSubject headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"Subject"]]
	[[columnDate headerView] setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"Date"]]

	//var emailsUnreadColumnView = [[EmailsUnreadColumnView alloc] initWithFrame:CGRectMake(0, 0, 22, 21)];
	//[columnUnread setDataView:emailsUnreadColumnView];


    // Toolbar customization
    // Reading pane initial view is parallel
    [self setDisplayedViewKey:@"ParallelView"];
    [mailSplitView setVertical:YES];
    [fromTableColumn setHidden:YES];
    [dateTableColumn setHidden:YES];
    [subjectTableColumn setWidth:SMSubjectTableColumnWidthParallelView];
    [emailsHeaderView setRowHeight:SMEmailTableViewRowHeightParallelView];

    var toolbarColor = [CPColor colorWithPatternImage:
                        [[CPImage alloc] initWithContentsOfFile:
                         [[CPBundle mainBundle] pathForResource:"toolbar_background_color.png"]
                                                           size:CGSizeMake(1, 59)]];

    if ([CPPlatform isBrowser]) [[toolbar _toolbarView] setBackgroundColor:toolbarColor];
    
    [toolbar validateVisibleItems];
    
    // Switcher images
    cachedSwitcherTraditionalViewOnImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherTraditionalViewOnIcon.png"] size:CGSizeMake(19, 16)];
    cachedSwitcherTraditionalViewOffImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherTraditionalViewOffIcon.png"] size:CGSizeMake(19, 16)];
    cachedSwitcherParallelViewOnImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherParallelViewOnIcon.png"] size:CGSizeMake(19, 16)];
    cachedSwitcherParallelViewOffImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherParallelViewOffIcon.png"] size:CGSizeMake(19, 16)];
    
    
	// Localize
	[fromLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"From"]]];
	[toLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"To"]]];
	[dateLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Date"]]];
	[subjectLabel setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Subject"]]];
    
}

-(void)prepareMailWindow:(id)sender {
    var authenticationController = [HNAuthController sharedController];
    if ([authenticationController isAuthenticated]) {
        imap = [[Imap alloc] init];
        imap.delegate = self;
        
        [imap getMailboxes];
        
        // Terrible code bellow; CIB conversion doesnt work properly for CPOutlineView
        // Configure the CPOutlineView
        mailboxesTableView = [[CPOutlineView alloc] initWithFrame:[mailboxesScrollview frame]];
        var column = [[CPTableColumn alloc] initWithIdentifier:@"Mailbox"];
        [column setWidth:190];
        [column setMinWidth:190];
        var mailboxColumnView = [[MailboxColumnView alloc] initWithFrame:CGRectMake(0, 0, 500, 24)];
        [column setDataView:mailboxColumnView];
        [mailboxesTableView setHeaderView:nil];
        [mailboxesTableView setCornerView:nil];
        [mailboxesTableView addTableColumn:column];
        [mailboxesTableView setOutlineTableColumn:column];
        [mailboxesTableView setDataSource:self];
        [mailboxesTableView setDelegate:self];
        [mailboxesTableView setBackgroundColor:mailboxesScrollview.backgroundColor];			
        [mailboxesScrollview setDocumentView:mailboxesTableView];
        [mailboxesTableView setAutoresizingMask: mailboxesScrollview.autoresizingMask];
        [mailboxColumnView setAutoresizingMask: mailboxesScrollview.autoresizingMask];	
        [mailboxesTableView sizeLastColumnToFit];
        [loadingLabel setObjectValue:@"Loading Mailboxes..."];


        // Cardano
        
        mailboxes = [[CPArray alloc] init];
        mailboxesOthers = [[CPArray alloc] init];
        mailHeaders = [[CPArray alloc] init];
        
        imapServer = [[HNRemoteService alloc] initForScalaTrait:@"com.smartmobili.service.ImapService"
                                                   objjProtocol:nil
                                                       endPoint:nil
                                                       delegate:self];
        
        [imapServer listMailboxes:@""
                         delegate:@selector(imapServerListMailboxesDidChange:) 
                            error:nil];

    }
    [self showWindow:sender];
}


-(void)showWindow:(id)sender {
    var authenticationController = [HNAuthController sharedController];
    if ([authenticationController isAuthenticated]) {        
        [theWindow center];
        [theWindow makeKeyAndOrderFront:self];        
    }
}

#pragma mark -
#pragma mark Cardano ImapService delegate

- (void)imapServerListMailboxesDidChange:(CPArray)result {
    
    // This could be done using predicates
    for (var i = 0; i < [result count]; i++) {
        var folder = [result objectAtIndex:i];
        if ([folder isDefaultFolder]) {
            mailboxes = [mailboxes arrayByAddingObject:folder];
        } else {
            mailboxesOthers = [mailboxesOthers arrayByAddingObject:folder];
        }
    }
        
    [mailboxesTableView reloadData];
	[loadingLabel setObjectValue:@"Mailboxes Loaded. Loading Headers for INBOX..."];
    
    // FIXME: this may cause an unwanted opening of the mailbox header 
    // whenever the client creates or deletes a folder
    [mailboxesTableView expandItem:nil expandChildren:YES];

	// Select INBOX by default
	selectedMailBox = @"Inbox";
    [imapServer headersForFolder:selectedMailBox
                        delegate:@selector(imapServerHeadersForFolderDidChange:) 
                           error:nil];

    // index set 1 is the Inbox mailbox
    [mailboxesTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];	

}

- (void)imapServerHeadersForFolderDidChange:(CPArray)result {
    // Result is an array with SMMailHeader elements
    mailHeaders = result;
    [emailsHeaderView reloadData];

    // FIXME: The selected mail should be the most recent
    [emailsHeaderView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    //CPLog.debug(@"%@%@", _cmd, result);
}

- (void)imapServerMailContentDidReceived:(SMMailContent)mailContent {
    //CPLog.debug(@"%@%@", _cmd, mailContent);
    if ([mailContent respondsToSelector:@selector(body)]) {
        [toContent setObjectValue:[mailContent toJoin]];
        [dateContent setObjectValue:[mailContent date]];
        [fromContent setObjectValue:[mailContent from]];
        [subjectContent setObjectValue:[mailContent subject]];

        var attachment = [self sectionForAttachment:[mailContent attachment]];
        // Build the whole message
        [webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><head></head><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@%@</body></html>", [mailContent body], attachment]];
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

- (void)reload {
    [webView reload:self];
}

- (CPString)sectionForAttachment:(CPArray)attachments {
    // Build the list of attachments
    var attachmentSection = @"";
    for (var i = 0; i < [attachments count]; i++) {
        attachmentSection = [attachmentSection stringByAppendingString:[CPString stringWithFormat:@"<div class=''><ul><li><a href='%@'>%@</a></li></ul></div>", [attachments objectAtIndex:i],[attachments objectAtIndex:i]]];
    }
    return attachmentSection;
}

#pragma mark -
#pragma mark Actions
- (IBAction) compose: (id) sender 
{
	var indexesSelectedEmail = emailsHeaderView._selectedRowIndexes;
	if ([indexesSelectedEmail count] == 1) 
	{
		var row = [emailsHeaderView selectedRow];
		var tblColumn = [emailsHeaderView tableColumnWithIdentifier:@"UID"];	
		var message_id = [self tableView:emailsHeaderView objectValueForTableColumn:tblColumn row:row];		
		CPLog.trace(message_id);
        
		//
		_composeController = [[ComposeController alloc] init];
		var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Compose.cib"]];
		[cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:_composeController forKey:CPCibOwner]];
	}
}

- (IBAction)switchMailOrientation:(id)sender 
{
    // Select the switch view in the toolbar
    // in order to update it
    var toolbarItems = [toolbar items];
    var theSwitcher;
    for (var i = 0; i < [toolbarItems count]; i++) {
        if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus") {
            theSwitcher = [[toolbarItems objectAtIndex:i] view];
        }
    }
    
    // Locate right and below menu items
    var viewMenu = [[[CPApplication sharedApplication] mainMenu] itemWithTag: @"SMViewMenu"];
    var readingPaneMenu = [[viewMenu submenu] itemWithTag:@"SMReadingPaneMenu"];
    
    var rightMenuItem = [[readingPaneMenu submenu] itemWithTag:@"ParallelView"];
    var belowMenuItem = [[readingPaneMenu submenu] itemWithTag:@"TraditionalView"];

    
    // By default select the tag
    var viewOption = [sender tag];

    // If the message is sent by the bar switcher,
    // then the selected tag is needed
    if (viewOption == @"changeViewStatus") {
        viewOption = [sender selectedTag];
    }
    
    switch (viewOption) {
        case @"TraditionalView":
            [mailSplitView setVertical:NO];
            if (theSwitcher) {
                [theSwitcher selectSegmentWithTag:@"TraditionalView"];
                [theSwitcher setImage:cachedSwitcherTraditionalViewOnImage forSegment:0];
                [theSwitcher setImage:cachedSwitcherParallelViewOffImage forSegment:1];
            }
            [belowMenuItem setState:CPOnState];
            [rightMenuItem setState:CPOffState];
            [fromTableColumn setHidden:NO];
            [dateTableColumn setHidden:NO];
            [subjectTableColumn setWidth:originalSubjectTableColumnWidth];
            [emailsHeaderView setRowHeight:SMEmailTableViewRowHeightTraditionalView];
            break;            
        case @"ParallelView":
            [mailSplitView setVertical:YES];
            if (theSwitcher) {
                [theSwitcher selectSegmentWithTag:@"ParallelView"];
                [theSwitcher setImage:cachedSwitcherTraditionalViewOffImage forSegment:0];
                [theSwitcher setImage:cachedSwitcherParallelViewOnImage forSegment:1];
            }
            [belowMenuItem setState:CPOffState];
            [rightMenuItem setState:CPOnState];
            [fromTableColumn setHidden:YES];
            [dateTableColumn setHidden:YES];
            [subjectTableColumn setWidth:SMSubjectTableColumnWidthParallelView];
            [emailsHeaderView setRowHeight:SMEmailTableViewRowHeightParallelView];
            break;
        default:
            [mailSplitView setVertical:NO];        
            break;
    }
	
	[mailboxesTableView sizeLastColumnToFit];
}

#pragma mark -
#pragma mark Toolbar Delegate

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, "searchField", "composeMail", "refreshMailbox", "deleteMail", "replyMail", "switchViewStatus", "logo"];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    var items = [ "composeMail", "refreshMailbox", CPToolbarFlexibleSpaceItemIdentifier, "deleteMail", "replyMail", CPToolbarFlexibleSpaceItemIdentifier, "switchViewStatus", "searchField"];
    
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
            [aSwitch selectSegmentWithTag:@"ParallelView"];
            
            [aSwitch setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherTraditionalViewOffIcon.png"] size:CGSizeMake(19, 16)] forSegment:0];
            [aSwitch setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"SMSwitcherParallelViewOnIcon.png"] size:CGSizeMake(19, 16)] forSegment:1];
            
            
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
    var mainBundle = [CPBundle mainBundle];
    var iconPath = [[CPString alloc] initWithFormat:@"Icons/%@.png", [itemIdentifier lowercaseString]];
    var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:iconPath] size:CPSizeMake(24, 24)];
    [toolbarItem setImage:image];
    [toolbarItem setAlternateImage:image];
    [toolbarItem setTarget:self];
    var selector = CPSelectorFromString([CPString stringWithFormat:@"%@:", itemIdentifier]);
    [toolbarItem setAction:selector];
    [toolbarItem setLabel:[[TNLocalizationCenter defaultCenter] localize:itemIdentifier]];
    [toolbarItem setMinSize:CGSizeMake(32, 32)];
    [toolbarItem setMaxSize:CGSizeMake(32, 32)];

}

- (void)deleteMail:(id)sender {
    CPLog.debug(@"%@", _cmd);
}

- (void)replyMail:(id)sender {
    CPLog.debug(@"%@", _cmd);    
}

- (void)refreshMailbox:(id)sender {
    CPLog.debug(@"%@", _cmd);
    [imapServer synchronizeAll:@""
                      delegate:nil
                         error:nil];

}

#pragma mark -
#pragma mark OutlineView Datasource/Delegate
- (BOOL)outlineView:(CPOutlineView)outlineView shouldSelectItem:(id)item {
	return ([item name] != @"Mailboxes" && [item name] != @"Others");
}

- (id)outlineView:(CPOutlineView)outlineView child:(int)index ofItem:(id)item 
{
    // Root item
    if (item === nil) 
	{
        // Creates the Mailboxes and Others headers
        mailboxesHeader = [[SMMailbox alloc] initWithName:@"Mailboxes" count:0 unread:0];
        othersHeader = [[SMMailbox alloc] initWithName:@"Others" count:0 unread:0];
        var res = [mailboxesHeader, othersHeader];
        return [res objectAtIndex:index];
    } 
	else if ([item name] == @"Mailboxes") 
	{
        return [mailboxes objectAtIndex:index];
	} 
	else if ([item name] == @"Others") 
	{
        return [mailboxesOthers objectAtIndex:index];
    }
}

- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item 
{
    
	if ([mailboxes count] == 0) {
		return 0;
	}
    if (item === nil) {
		// Root object, so returns 2 to allow Mailboxes and Others
        return 2;
    } else if (!item || item == null) {
        return 0;
    } else if ([item name] == @"Mailboxes") {
		return [mailboxes count];
	} else if ([item name] == @"Others") {
		return [mailboxesOthers count];
	} else {
        0
    }
}

- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item 
{
	if ([mailboxes count] == 0) 
	{
		return NO;
	} 
	else 
	{
		return ([item name] == @"Mailboxes") || ([item name] == @"Others");
	}
}

- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item 
{
	return item;
}

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification 
{
    //CPLog.debug(@"Notification object: %@", [aNotification object]);
	// If i just want to select, and not reload
	if (justSelectMailboxes) {
		justSelectMailboxes = NO;
		return;
	}
	// User selected one/another mailbox
    var mailboxesHeaderArray = [CPArray arrayWithObject:mailboxesHeader];
    var othersHeaderArray = [CPArray arrayWithObject:othersHeader];
    
    // MailboxesAll is schematically [mailboxesHeader, mailboxes, othersHeader, mailboxesOthers]
    // in a well formed, Cappuccino array
    var mailboxesAll = [mailboxesHeaderArray arrayByAddingObjectsFromArray:mailboxes];
    mailboxesAll = [mailboxesAll arrayByAddingObject:othersHeaderArray];
    mailboxesAll = [mailboxesAll arrayByAddingObjectsFromArray:mailboxesOthers];
    
    var selectedMailboxIndexes = [mailboxesTableView selectedRowIndexes];
    var selectedMailboxName = @"Inbox";
    if ([selectedMailboxIndexes count] == 1) {
        selectedMailboxName = [[mailboxesAll objectAtIndex:[selectedMailboxIndexes firstIndex]] name];
        //CPLog.debug(@"Selected Mailbox %@", selectedMailboxName);
        //CPLog.debug(@"Mailboxes All %@", mailboxesAll);
        //CPLog.debug(@"Indexes: %@", selectedMailboxIndexes);

        [loadingLabel setObjectValue:[[CPString alloc] initWithFormat:@"Mailboxes Loaded. Loading Headers for %@...", selectedMailboxName]];
        
        [emailsHeaderView deselectAll];
        [imapServer headersForFolder:selectedMailboxName
                         delegate:@selector(imapServerHeadersForFolderDidChange:) 
                            error:nil];        
	}
    
	if (selectedMailboxName == nil) {
		// Deselected Mailbox
		selectedMailboxName = nil;
		mailHeaders = nil;
		[emailsHeaderView reloadData];
		[loadingLabel setObjectValue:@"No Mailbox Selected."];
	}
}

- (int)getIndexByMailbox:(CPString)mailbox 
{
	if ((mailbox == @"Mailboxes") || (mailbox == @"Others")) {
		return nil;
	}
	for (var i = 0; i < [mailboxes count]; i++) {
		if ([mailboxes objectAtIndex:i] == mailbox) {
			return i + 1;
		}
	}
	for (var i = 0; i < [mailboxes count]; i++) {
		if ([mailboxes objectAtIndex:i] == mailbox) {
			return i + 5;
		}
	}
	return nil;
}

- (NSString)selectedMailboxByIndex: (int) index 
{
    // I. Cases: this does not work with mailboxesOthers
	if ((index == 0) || (index == [mailboxes count] + 1)) {
		return nil;
	}
	if (index <= [mailboxes count]) {
		return [mailboxes objectAtIndex:index - 1];
	} else {
		return [mailboxes objectAtIndex:(index - [mailboxes count] - 2)];
	}
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
    [[emailContextMenu addItemWithTitle:@"Delete" action:nil keyEquivalent:nil] setTarget:self];
	
    return emailContextMenu;
}


- (IBAction)openMessage:(id)sender
{
	CPLog.trace(@"openMessage");
	
	_composeController = [[ComposeController alloc] init];
	[_composeController setImap:imap prevDelegate:imap.delegate];
	imap.delegate = _composeController;
	
	
	var row = [emailsHeaderView selectedRow];
	selectedEmail = [[mailHeaders objectAtIndex:row] md5];
	[loadingLabel setObjectValue:@"Loading E-mail Selected..."];
	[imap getMailContent:selectedEmail];
	
    
	var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Compose.cib"]];
	[cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:_composeController forKey:CPCibOwner]];
}



-(int)numberOfRowsInTableView:(CPTableView)aTableView 
{
	// E-mails
	if ((imap != nil) && (mailHeaders != nil)) {
		return [mailHeaders count];
	} else {
		return 0;
	}
}
-(id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow 
{
    var result = nil;
    
	if ((imap != nil) && (mailHeaders != nil)) 
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
		} 
		else if ([[aTableColumn identifier] isEqualToString:@"Subject"]) 
		{
            var toolbarItems = [toolbar items];
            var viewSelected;
            for (var i = 0; i < [toolbarItems count]; i++) {
                if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus") {
                    viewSelected = [[[toolbarItems objectAtIndex:i] view] selectedTag];
                }
            }
            switch (viewSelected) {
                case @"TraditionalView":
                    result = [[mailHeaders objectAtIndex:aRow] subject];       
                    break;            
                case @"ParallelView":
                    var email = [[SMEmail alloc] init];
                    [email setFrom:[[mailHeaders objectAtIndex:aRow] fromEmail]];
                    [email setSubject:[[mailHeaders objectAtIndex:aRow] subject]];
                    [email setDate:[[mailHeaders objectAtIndex:aRow] date]];
                    result = email;
                    break;
                default:
                    break;
            }
		} 
		else if ([aTableColumn._identifier isEqualToString:@"Date"]) 
		{
			result = [[mailHeaders objectAtIndex:aRow] date];
		} 
		else if ([[aTableColumn identifier] isEqualToString:@"SMUnreadTableColumn"]) 
		{
			result = [[mailHeaders objectAtIndex:aRow] isSeen] ? nil : cachedIsReadImage;
		}
	}
    
    return result;
}

- (CPView)tableView:(CPTableView)tableView dataViewForTableColumn:(CPTableColumn)tableColumn row:(int)row {
    // Select the switch view in the toolbar
    // in order to know the orientation selected
    var toolbarItems = [toolbar items];
    var viewSelected;
    for (var i = 0; i < [toolbarItems count]; i++) {
        if ([[toolbarItems objectAtIndex:i] itemIdentifier] == @"switchViewStatus") {
            viewSelected = [[[toolbarItems objectAtIndex:i] view] selectedTag];
        }
    }
        
    var newDataView = [tableColumn dataView];
    if ([[tableColumn identifier] isEqualToString:@"Subject"]) {
        switch (viewSelected) {
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

- (IBAction) refresh: (id) sender {
	console.log(@"Refresh...");
}

#pragma mark -
#pragma mark Imap Delegate
-(void) gotMailboxes:(Imap) aImap 
{
	[mailboxesTableView reloadData];
	[loadingLabel setObjectValue:@"Mailboxes Loaded. Loading Headers for INBOX..."];
	// Select INBOX by default
	selectedMailBox = @"Inbox";
	[imap getMailHeaders:selectedMailBox];
//    [imapServer headersForFolder:selectedMailBox
//                        delegate:@selector(imapServerHeadersForFolderDidChange:) 
//                           error:nil];
}

-(void) gotMailHeaders:(Imap) aImap 
{
	[emailsHeaderView reloadData];
	selectedEmail = nil;
	[loadingLabel setObjectValue:@"Mail Headers Loaded."];
	// Mark Selected
	justSelectMailboxes = YES;
	var indexSelectedMailBox = [self getIndexByMailbox:selectedMailBox];
	[mailboxesTableView selectRowIndexes:[[CPIndexSet alloc] initWithIndex:indexSelectedMailBox] byExtendingSelection:NO];	
	justSelectMailboxes = NO;
	// Select the first e-mail by default
	selectedEmail = [[mailHeaders objectAtIndex:0] md5];
	[loadingLabel setObjectValue:@"Loading E-mail Selected..."];
	[imap getMailContent:selectedEmail];	
	// Mark Selected E-mail
	justSelect = YES;
	[emailsHeaderView selectRowIndexes:[[CPIndexSet alloc] initWithIndex:0] byExtendingSelection:NO];	
}

- (void) gotMailContent:(Imap) aImap 
{	
	[loadingLabel setObjectValue:@"Mail Content Loaded."];
	[toContent setObjectValue:imap.mailContent.ToJoin];
	[dateContent setObjectValue:imap.mailContent.Date];
	[fromContent setObjectValue:imap.mailContent.From];
	[subjectContent setObjectValue:imap.mailContent.Subject];
	[webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@</body></html>", imap.mailContent.HTMLBody]];
}

- (void) clearMailContent 
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

- (void)tableViewSelectionDidChange:(CPNotification)aNotification {
	// If i just want to select, and not reload
	if (justSelect) {
		justSelect = NO;
		return;
	}
	if ([aNotification object] == emailsHeaderView) {
		// Get the Delete and the Reply CPToolbarItem
		deleteItem = [toolbar._items objectAtIndex:3];
		replyItem = [toolbar._items objectAtIndex:4];
		
		// User selected one/another e-mail
		var indexesSelectedEmail = [emailsHeaderView selectedRowIndexes];
		if ([indexesSelectedEmail count] == 1) {
			selectedEmail = [[mailHeaders objectAtIndex:[indexesSelectedEmail firstIndex]] messageId];
			[loadingLabel setObjectValue:@"Loading E-mail Selected..."];
			[imap getMailContent:selectedEmail];
                        
            var mailboxesHeaderArray = [CPArray arrayWithObject:mailboxesHeader];
            var othersHeaderArray = [CPArray arrayWithObject:othersHeader];
            
            // MailboxesAll is schematically [mailboxesHeader, mailboxes, othersHeader, mailboxesOthers]
            // in a well formed, Cappuccino array
            var mailboxesAll = [mailboxesHeaderArray arrayByAddingObjectsFromArray:mailboxes];
            mailboxesAll = [mailboxesAll arrayByAddingObject:othersHeaderArray];
            mailboxesAll = [mailboxesAll arrayByAddingObjectsFromArray:mailboxesOthers];
            
            var selectedMailboxIndexes = [mailboxesTableView selectedRowIndexes];
            var selectedMailboxName = @"Inbox";
            if ([selectedMailboxIndexes count] == 1) {
                selectedMailboxName = [[mailboxesAll objectAtIndex:[selectedMailboxIndexes firstIndex]] name];
            }
            [imapServer mailContentForMessageId:selectedEmail
                                         folder:selectedMailboxName
                                       delegate:@selector(imapServerMailContentDidReceived:) 
                                          error:nil];
			// Both Active
			[deleteItem setEnabled:YES];
			[replyItem setEnabled:YES];
		} else {
			// Deselected E-mail
			selectedEmail = nil;
			imap.mailContent = nil;
			[self clearMailContent];
			if ([indexesSelectedEmail count] == 0) {
				[loadingLabel setObjectValue:@"None E-mail selected."];
				// None Active
				[deleteItem setEnabled:NO];
				[replyItem setEnabled:NO];
			} else {
				[loadingLabel setObjectValue:@"Multiple E-mails selected."];
				// Only Delete active
				[deleteItem setEnabled:YES];
				[replyItem setEnabled:NO];
			}
		}
	}
}

#pragma mark -
#pragma mark CPSplitView delegate
- (void)splitViewDidResizeSubviews:(id) sender {
	[mailboxesTableView sizeLastColumnToFit];
}

- (void)didResizeView:(CPNotification)aNotification { 
	console.log(@"didResizeView");
}

//- (void)splitView:(CPSplitView)sender resizeSubviewsWithOldSize:(CGSize)oldSize
//{
//    var dividerThickness = [sender dividerThickness];
//    var leftRect = [[[sender subviews] objectAtIndex:0] frame];
//    var rightRect = [[[sender subviews] objectAtIndex:1] frame];
//    var newFrame = [sender frame];
//    
// 	leftRect.size.height = newFrame.size.height;
//	leftRect.origin = CGPointMake(0, 0);
//	rightRect.size.width = newFrame.size.width - leftRect.size.width - dividerThickness;
//	rightRect.size.height = newFrame.size.height;
//	rightRect.origin.x = leftRect.size.width + dividerThickness;
//    
// 	[[[sender subviews] objectAtIndex:0] setFrame:leftRect];
//	[[[sender subviews] objectAtIndex:1] setFrame:rightRect];
//}
//
//- (CGFloat)splitView:(CPSplitView)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(int)offset
//{
//    var subview = [[sender subviews] objectAtIndex:offset];
//    var subviewFrame = [subview frame];
//    var frameOrigin;
//
//    if ([sender isVertical]) {
//        frameOrigin = subviewFrame.origin.x;
//    } else {
//        frameOrigin = subviewFrame.origin.y;
//    }
//    
//    var minimumSize = SMOutlineViewMailPaneMinimumSize;
//    
//    return frameOrigin + minimumSize;
//}

- (CGFloat)splitView:(CPSplitView)splitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)dividerIndex
{
    return SMOutlineViewMailPaneMinimumSize;
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)dividerIndex
{
    return SMOutlineViewMailPaneMaximumSize;
}


#pragma mark -
#pragma mark Menu Item Validation
- (@action)selectAll:(id)sender
{
    var range = CPMakeRange(0, [emailsHeaderView numberOfRows]);
    var indexes = [CPIndexSet indexSetWithIndexesInRange:range];
    [emailsHeaderView selectRowIndexes:indexes byExtendingSelection:NO];
}

- (BOOL)shouldSelectAll {
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
    
    [aControl setValue:[CPColor colorWithCalibratedWhite:73.0/255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [aControl setValue:[CPColor colorWithCalibratedWhite:96.0/255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:222.0/255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [aControl setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
    
    [aControl setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
    [aControl setValue:[CPColor colorWithCalibratedWhite:0.0/255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
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
