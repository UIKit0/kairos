/*
 *  MailSourceViewController.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
*/

@import "MailSourceViewRows.j"
@import "../Views/SMSmallButton.j"

SMOutlineViewMailPaneMinimumSize = 210;
SMOutlineViewMailPaneMaximumSize = 400;

/*!
    Control the source view on the left side of the mail window. The source
    view allows the selection of mailboxes.
*/
@implementation MailSourceViewController : CPViewController
{
    @outlet MailController mailController;

    MailSourceViewRow headerMailboxes;
    MailSourceViewRow headerOthers;

    CPDictionary mailboxToItemMap;
}

- (void)awakeFromCib
{
    mailboxToItemMap = [CPMutableDictionary dictionary];
    headerMailboxes = [MailSourceViewRow headerWithName:@"Mailboxes"];
    headerOthers = [MailSourceViewRow headerWithName:@"Others"];

    var plusImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPButtonBar class]] pathForResource:@"plus_button.png"] size:CGSizeMake(11, 12)],
        button = [SMSmallButton buttonWithTitle:@""];
    [button setImage:plusImage];
    [button sizeToFit];
    [button setImageDimsWhenDisabled:YES];
    [button setTarget:self];
    [button setAction:@selector(addMailbox:)];

    [headerOthers setButton:button];

    var view = [self view],
        column = [[view tableColumns] objectAtIndex:0],
        mailboxColumnView = [[MailboxColumnView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([view bounds]), 24)];
    [mailboxColumnView setAutoresizingMask:CPViewWidthSizable];
    [column setDataView:mailboxColumnView];

    [view setBackgroundColor:[CPColor colorWithHexString:@"D6DDE3"]];

    // Work around Cappuccino bug #1411 in IE8. Can be removed once #1411 has been fixed and
    // Cappuccino updated (after Cappuccino 0.9.5).
    if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
        [view setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleRegular];
}

- (void)reload
{
    var view = [self view];
    mailboxToItemMap = [CPMutableDictionary dictionary];
    [view reloadData];
}

- (void)reloadAndSelectInbox
{
    [self reload];
    // The inbox is always the first mailbox.
    var mailboxes = [self mailboxes];
    [self selectMailbox: mailboxes ? mailboxes[0] : nil];
}

- (int)selectedRowIndex
{
    var view = [self view],
        selectedRowIndexes = [view selectedRowIndexes];

    return [selectedRowIndexes count] ? [selectedRowIndexes firstIndex] : CPNotFound;
}

- (id)selectedItem
{
    var view = [self view],
        indexes = [view selectedRowIndexes];

    return [indexes count] == 1 ? [view itemAtRow:[indexes firstIndex]] : nil;
}

- (SMMailbox)selectedMailbox
{
    // In the future if something other than a mailbox can be selected and is selected, return nil here.
    return [[self selectedItem] object];
}

- (void)selectMailbox:(SMMailbox)aMailbox
{
    var view = [self view];
    // Expand the section containing the mailbox.
    [view expandItem:[aMailbox isSpecial] ? headerMailboxes : headerOthers]

    var item = [mailboxToItemMap valueForKey:[aMailbox UID]];
    [self selectItem:item];
}

- (void)selectItem:anItem
{
    [self revealItem:anItem];
    var view = [self view],
        index = [view rowForItem:anItem];
    [[self view] selectRowIndexes:(index != CPNotFound ? [CPIndexSet indexSetWithIndex:index] : [CPIndexSet indexSet]) byExtendingSelection:NO];

}

- (void)revealItem:(id)anItem
{
    var parent = anItem,
        view = [self view];
    while (parent = [view parentForItem:parent])
    {
        if (![view isItemExpanded:parent])
            [view expandItem:parent];
    }
}

- (void)addMailbox:(id)sender
{
    var newMailbox = [[mailController mailAccount] createMailbox:self];
    [self reload];
    [self selectMailbox:newMailbox];

    var view = [self view],
        rowIndex = [[view selectedRowIndexes] firstIndex];
    if (rowIndex !== nil && rowIndex !== CPNotFound)
        [view editColumn:0 row:rowIndex withEvent:nil select:YES];

}

#pragma mark -
#pragma mark OutlineView Datasource and Delegate

- (BOOL)outlineView:(CPOutlineView)outlineView shouldSelectItem:(id)item
{
    return ![item isHeader];
}



/*!
    Convenience method to get the source mailboxes.
*/
- (CPArray)mailboxes
{
    return [[mailController mailAccount] mailboxes];
}

/*!
    Return the number of mailboxes shown in the main "Mailboxes" section. The remaining
    are to be shown in the "Other" section.
*/
- (int)mainMailboxesCount
{
    var mailboxes = [self mailboxes],
        count = [mailboxes count],
        i = 0;
    // SMMailAccount places all the special mailboxes on top.
    while (i < count && [mailboxes[i] isSpecial])
        i++;
    return i;
}

- (id)outlineView:(CPOutlineView)outlineView child:(int)index ofItem:(id)item
{
    if (!mailController)
        return nil;

    // Root item
    if (item === nil)
        return index == 0 ? headerMailboxes : headerOthers;

    if (item === headerOthers)
        index += [self mainMailboxesCount];

    var mailboxes = [self mailboxes],
        mailbox = [mailboxes objectAtIndex:index];

    // This map is used to select mailboxes programatically.
    var child = nil;
    if (![mailboxToItemMap containsKey:[mailbox UID]])
    {
        child = [MailSourceViewRow rowWithName:[mailbox name] icon:nil object:mailbox];
        [mailboxToItemMap setValue:child forKey:[mailbox UID]];
    }
    else
        child = [mailboxToItemMap valueForKey:[mailbox UID]];

    return child;
}

- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item
{
    if (!mailController)
        return 0;

    if (item === nil)
    {
        // Root object, so returns 2 to allow Mailboxes and Others
        return 2;
    }
    else if (item === headerMailboxes)
        return [self mainMailboxesCount];
    else if (item === headerOthers)
        return [[self mailboxes] count] - [self mainMailboxesCount];
    else
        return 0;
}

- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item
{
    return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
}

- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return item;
}

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    //CPLog.debug(@"Notification object: %@", [aNotification object]);
    // If i just want to select, and not reload
    if ([mailController justSelectMailboxes])
    {
        justSelectMailboxes = NO;
        return;
    }
    [mailController setSelectedMailbox:[self selectedMailbox]];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView shouldEditTableColumn:(CPTableColumn)aColumn item:(id)anItem
{
    return ![anItem isHeader] && ![[anItem object] isSpecial];
}

- (void)outlineView:(CPOutlineView)anOutlineView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    var mailbox = [anItem object];
    if (![mailbox isSpecial])
    {
        [mailbox renameTo:aValue];
        [self reload];
    }
}

#pragma mark -
#pragma mark CPSplitView delegate

- (CGFloat)splitView:(CPSplitView)splitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)dividerIndex
{
    return SMOutlineViewMailPaneMinimumSize;
}

- (CGFloat)splitView:(CPSplitView)splitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)dividerIndex
{
    return SMOutlineViewMailPaneMaximumSize;
}

/*!
    When the window is resized, we don't want the source view to change size, only the main right hand
    side of the main split view. This is the way Apple Mail works for instance. Beyond being just good
    UI, it's also important so we can set an initial size for the source view without that size immediately
    being changed due to the initial window resize - the user's browser is unlikely to be the same size
    as our IB window size.
*/
- (void)splitView:(CPSplitView)sender resizeSubviewsWithOldSize:(CGSize)oldSize
{
    var subviews = [sender subviews],
        left = subviews[0],
        right = subviews[1],
        dividerThickness = [sender dividerThickness],
        newFrame = [sender frame],
        leftFrame = [left frame],
        rightFrame = [right frame];

    // Update the subview frames so that any change in width is applied to the right hand side.
    leftFrame.size.height = newFrame.size.height;
    rightFrame.size.height = newFrame.size.height;

    leftFrame.origin = CGPointMake(0, 0);
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    [left setFrame:leftFrame];
    [right setFrame:rightFrame];
}

@end
