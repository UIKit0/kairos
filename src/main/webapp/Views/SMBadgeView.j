/*
 *  SNBadgeView
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */


@import <AppKit/CPTextField.j>

var SMBadgeViewBackgroundColor = nil,
    SMBadgeViewHighlightedBackgroundColor = nil;

@implementation SMBadgeView : CPTextField

+ (void)initialize
{
    SMBadgeViewBackgroundColor = CPColorWithImages([
        ['source-badge-left.png', 8, 17],
        ['source-badge-center.png', 1, 17],
        ['source-badge-right.png', 8, 17]
    ]);
    SMBadgeViewHighlightedBackgroundColor = CPColorWithImages([
        ['source-badge-highlighted-left.png', 8, 17],
        ['source-badge-highlighted-center.png', 1, 17],
        ['source-badge-highlighted-right.png', 8, 17]
    ]);
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
    }
    return self;
}

- (void)_init
{
    [self setBezeled:NO];

    [self setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [self setValue:[CPColor colorWithHexString:"FDFDFD"] forThemeAttribute:@"text-color"];
    [self setValue:[CPColor colorWithHexString:"3884C9"] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];

    [self setValue:[CPColor colorWithCSSString:@"rgba(0, 0, 0, 0.2)"] forThemeAttribute:@"text-shadow-color"];
    [self setValue:[CPColor clearColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelectedDataView];

    [self setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [self setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self setAlignment:CPCenterTextAlignment];
    [self setValue:CGInsetMake(2.0, 7.0, 1.0, 7.0) forThemeAttribute:"content-inset"];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    [self updateBackground];
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    [self updateBackground];
}

- (void)updateBackground
{
   [self setBackgroundColor:![self hasThemeState:CPThemeStateSelectedDataView] ? SMBadgeViewBackgroundColor : SMBadgeViewHighlightedBackgroundColor];
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];

    // Make the badge wide enough to fit its number.
    var bounds = [self bounds];
    [self setFrameSize:CGSizeMake([self _minimumFrameSize].width, bounds.size.height)];
}

@end
