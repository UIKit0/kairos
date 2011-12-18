/*
 *	SMEmailService.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@implementation SMEmailService : CPObject
{
    CPArray emails @accessors;

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




@end