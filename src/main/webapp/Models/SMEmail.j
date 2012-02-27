/*
 *	SMEmail.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@import "SMRemoteObject.j"

/* Comment by Victor Kazarinov: SMEmail is used to show headers list in Vertical View, where
 * each line in table show several fields such as from, subject, date.
 */
@implementation SMEmail : SMRemoteObject
{
    /*! The mailbox the email belongs to. */
    SMMailbox mailbox @accessors;

    /*! The attachments belonging to this email. */
    CPArray attachments @accessors;

    CPString from @accessors;
    CPString subject @accessors;
    CPString date @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        attachments = [CPMutableArray array];
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

/*!
    Make sure attachments know they belong to this email.
*/
- (void)setAttachments:(CPArray)someAttachments
{
    [someAttachments makeObjectsPerformSelector:@selector(setEmail:) withObject:self];
    attachments = someAttachments;
}

- (void)insertObject:(id)anAttachment inAttachmentsAtIndex:(int)anIndex
{
    [anAttachment setEmail:self];
    [attachments insertObject:anAttachment atIndex:anIndex];
}

@end
