/*
 *  CPTableView+SelectAll.j
 *  Mail
 *
 *  Author: Vincent Richomme
 *  Copyright 2011 Smartmobili. All rights reserved.
*/

@import <AppKit/CPTableView.j>


@implementation CPTableView (VRKit)

- (void)keyDown:(CPEvent)anEvent
{
    if ((([anEvent keyCode] == 65) && ([anEvent modifierFlags] == CPCommandKeyMask) && [self allowsMultipleSelection]))
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])];

        [self selectRowIndexes:indexes byExtendingSelection:NO];
        return;
    }
    [self interpretKeyEvents:[anEvent]];
}






/*
- (void)keyDown:(CPEvent)anEvent
{
	var character		= [anEvent charactersIgnoringModifiers];
	var modifierFlags	= [anEvent modifierFlags];
	
	if ((modifierFlags & CPCommandKeyMask) && (character == @"a") && ([self allowsMultipleSelection]))
	{
		[self selectRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])] byExtendingSelection:NO];

    }
    [super keyDown:anEvent];
}
*/
@end
