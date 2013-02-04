/*
 *  MailSourceViewRows.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
*/

/**
    An item in the source view; could be one of the headers or a mail box. If the item
    represents a mailbox, object will be the mailbox.
*/

@import <AppKit/CPButton.j>

@implementation MailSourceViewRow : CPObject
{
    CPString    name @accessors;
    CPString    iconName @accessors;
    boolean     isHeader @accessors;
    CPButton    button @accessors;
    CPString    object @accessors;
}

+ (id)rowWithName:(CPString)aName icon:(CPString)anIcon object:(id)anObject
{
    var r = [self new];
    [r setName:aName];
    [r setIconName:anIcon];
    [r setObject:anObject];
    return r;
}

+ (id)headerWithName:(CPString)aName
{
    var r = [self new];
    [r setName:aName];
    [r setIsHeader:YES];
    return r;
}

@end
