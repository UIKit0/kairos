/*
 * CPString+Custom.j
 *  Mail
 *
 *  Created by Vincent Richomme on 15/02/11.
 *  Copyright __MyCompanyName__ 2011. All rights reserved.
*/

@import <Foundation/CPString.j>

@implementation CPString (VRKit)

- (BOOL)isJSONValid
{
	var c = [self characterAtIndex:0];
    return (c == '[' || c == '{');
}



- (CPString)lowercaseAndCapitalized
{
	var lowercase =  [self lowercaseString];
	return [lowercase capitalizedString];
}




@end