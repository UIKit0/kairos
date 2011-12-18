/*
 *	SMEmail.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@implementation SMEmail : CPObject
{
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

- (CPString)formattedDate {
    CPLog.debug(@"%@", date);
    return date;
}

@end