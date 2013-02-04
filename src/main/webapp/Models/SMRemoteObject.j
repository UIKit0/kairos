/*
 *  SMRemoteObject.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

/*!
    A RemoteProxy represents some object which exists in the server and this app is
    mirroring locally. It can be "new", for objects yet to actually be created on
    the server.
*/

@import <Foundation/CPDate.j>

@implementation SMRemoteObject : CPObject
{
    CPDate  lastChangedAt @accessors;
    CPDate  lastSyncedAt @accessors;
}

- (boolean)isNew
{
    return !lastSyncedAt;
}

- (void)save
{
    lastSyncedAt = [CPDate new];
}

- (void)markAsDirty
{
    lastChangedAt = [CPDate new];
}

- (boolean)isDirty
{
    return lastChangedAt && (!lastSyncedAt || [lastChangedAt laterDate:lastSyncedAt]);
}

@end
