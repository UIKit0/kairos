/*
 *  CPDate+Formatting.j
 *  Categories
 *
 *  Author:  Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
*/

@implementation CPDate (Formatting)

/*!
    Format a date in the standard format for the app. Could easily be made locale sensitive
    in the future.
*/
- (CPString)formattedDescription
{
    return self.toLocaleDateString();
}

@end
