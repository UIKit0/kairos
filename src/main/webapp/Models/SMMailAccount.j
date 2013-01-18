/*
 *  SMMailAccount.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

/*!
    A mail account contains one or more mail boxes.
*/

@import "SMRemoteObject.j"
@import "../ServerConnection.j"
@import "SMMailbox.j"

@implementation SMMailAccount : SMRemoteObject
{
    CPArray         mailboxes @accessors;

    ServerConnection        _serverConnection @accessors;

    id              delegate @accessors;
    boolean         isReloading;
}

- (id)init
{
    if (self = [super init])
    {
        mailboxes = [CPArray array];

        // In the future we might want to support more than one account, but for now everything is set up
        // for a single account at a time.

        /*imapServer = [[HNRemoteService alloc] initForScalaTrait:@"com.smartmobili.service.ImapService"
                                                   objjProtocol:nil
                                                       endPoint:nil
                                                       delegate:self];*/
        _serverConnection = [[ServerConnection alloc] init];
    }
    return self;
}

- (void)load
{
    isReloading = YES;

    [_serverConnection callRemoteFunction:@"listMailfolders"
                    withFunctionParametersAsObject:nil
                    delegate:self
                    didEndSelector:@selector(imapServerListMailboxesDidChange:withParametersObject:)
                    error:nil];
}

- (void)setMailboxes:(CPArray)someMailboxes
{
    mailboxes = [someMailboxes sortedArrayUsingSelector:@selector(compareInverseDisplayPriority:)];
    [mailboxes makeObjectsPerformSelector:@selector(setMailAccount:) withObject:self];
}

- (SMMailBox)createMailbox:(id)sender
{
    // TODO: find empty name if "Unnamed" is already exists. E.g. it should be "Unnamed2" (Perhaps not need this, Unnamed is fine?).

    var r = [[SMMailbox alloc] initWithName:@"Unnamed" count:0 unread:0];
    [[self mutableArrayValueForKey:@"mailboxes"] addObject:r];
    // Don't create the new mailbox yet. We want to wait until it has been given a name. The rename code
    // will call the 'save' method.
    return r;
}

- (void)removeMailbox:(SMMailbox)aMailbox
{
    if ([mailboxes containsObject:aMailbox])
    {
        [[self mutableArrayValueForKey:@"mailboxes"] removeObject:aMailbox];
        [aMailbox setMailAccount:nil];
    }
}

#pragma mark -
#pragma mark Remote ImapService delegate

- (void)imapServerListMailboxesDidChange:(id)sender withParametersObject:parametersObject
{
    var listOfFolders = parametersObject.listOfFolders,
        result = [CPArray array];

    for (var i = 0; i < listOfFolders.length; i++)
    {
        var mailBox = [[SMMailbox alloc] initWithName:listOfFolders[i].label count:listOfFolders[i].count unread:listOfFolders[i].unread];
        result = [result arrayByAddingObject:mailBox];
    }

    [self setMailboxes:result];

    if (isReloading)
    {
        isReloading = NO;
        if ([delegate respondsToSelector:@selector(mailAccountDidReload:)])
            [delegate mailAccountDidReload:self];
    }
}

@end
