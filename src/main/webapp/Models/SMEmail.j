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

    CPString from @accessors;
    CPString subject @accessors;
    CPString date @accessors;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end
