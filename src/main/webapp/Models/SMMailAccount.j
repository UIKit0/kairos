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
@implementation SMMailAccount : SMRemoteObject
{
    CPArray         mailboxes @accessors;

    HNRemoteService imapServer @accessors;

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

        // TODO: make imapServer in java
        imapServer = [[HNRemoteService alloc] initForScalaTrait:@"com.smartmobili.service.ImapService"
                                                   objjProtocol:nil
                                                       endPoint:nil
                                                       delegate:self];
    }
    return self;
}

- (void)load
{
    isReloading = YES;

    [imapServer listMailboxes:@""
                     delegate:@selector(imapServerListMailboxesDidChange:)
                        error:nil];
}

- (void)setMailboxes:(CPArray)someMailboxes
{
    mailboxes = [someMailboxes sortedArrayUsingSelector:@selector(compareInverseDisplayPriority:)];
    [mailboxes makeObjectsPerformSelector:@selector(setMailAccount:) withObject:self];
}

- (SMMailBox)createMailbox:(id)sender
{
    // TODO: find empty name in "Unnamed" is already exists. E.g. "Unnamed2".


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
        console.log("removing ", aMailbox);
        [[self mutableArrayValueForKey:@"mailboxes"] removeObject:aMailbox];
        [aMailbox setMailAccount:nil];
    }
}

#pragma mark -
#pragma mark Remote ImapService delegate

- (void)imapServerListMailboxesDidChange:(CPArray)result
{
    [self setMailboxes:result];

    if (isReloading)
    {
        isReloading = NO;
        if ([delegate respondsToSelector:@selector(mailAccountDidReload:)])
            [delegate mailAccountDidReload:self];
    }
}

@end
