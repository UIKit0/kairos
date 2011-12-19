/*
 *  SMSplitView.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

var SMSmallButtonBezelColor = nil,
    SMSmallButtonHighlightedBezelColor = nil,
    SMSmallButtonDisabledBezelColor = nil,
    SMSmallButtonHeight = 21;

/*!
    A split view which remembers its orientation if it has an auto save name.
*/
@implementation SMSplitView : CPSplitView
{
    BOOL shouldAutosaveVertical;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        shouldAutosaveVertical = YES;
    }
    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        shouldAutosaveVertical = YES;
    }
    return self;
}

- (void)setVertical:(BOOL)shouldBeVertical
{
    [super setVertical:shouldBeVertical];
    if (shouldAutosaveVertical)
        [self autosaveVertical];
}

- (void)autosaveVertical
{
    console.log("autosaveVertical");
    var autosaveName = [self verticalAutosaveName];
    if (!autosaveName)
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults];

    console.log("autosaveVertical: ", [self isVertical], "forKey:", autosaveName);
    [userDefaults setBool:[self isVertical] forKey:autosaveName];
}

/*!
    Based on private API. Might need change if _restoreFromAutosave is renamed in a future
    Cappuccino version.
*/
- (void)_restoreFromAutosave
{
    var autosaveName = [self verticalAutosaveName];
    if (!autosaveName)
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults],
        isVertical = [userDefaults boolForKey:autosaveName];

    shouldAutosaveVertical = NO;
    console.log("_restoreFromAutosave: ", isVertical, "forKey:", autosaveName);

    [self _setVertical:isVertical];
    shouldAutosaveVertical = YES;
}

- (CPString)verticalAutosaveName
{
    var autosaveName = [self autosaveName];
    if (!autosaveName)
        return nil;

    return @"SMSplitView Vertical Orientation " + autosaveName;
}

@end
