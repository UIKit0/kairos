/*
 *  SMSmallButton.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/CPButton.j>

var SMSmallButtonBezelColor = nil,
    SMSmallButtonHighlightedBezelColor = nil,
    SMSmallButtonDisabledBezelColor = nil,
    SMSmallButtonHeight = 21;


@implementation SMSmallButton : CPButton
{

}

+ (void)initialize
{
    SMSmallButtonBezelColor = CPColorWithImages([
        ['button-bezel-small-left.png', 3, 21],
        ['button-bezel-small-center.png', 1, 21],
        ['button-bezel-small-right.png', 3, 21]
    ]);
    SMSmallButtonHighlightedBezelColor = CPColorWithImages([
        ['button-bezel-small-highlighted-left.png', 3, 21],
        ['button-bezel-small-highlighted-center.png', 1, 21],
        ['button-bezel-small-highlighted-right.png', 3, 21]
    ]);
    SMSmallButtonDisabledBezelColor = CPColorWithImages([
        ['button-bezel-small-disabled-left.png', 3, 21],
        ['button-bezel-small-disabled-center.png', 1, 21],
        ['button-bezel-small-disabled-right.png', 3, 21]
    ]);
}

- (void)_init
{
    [self setValue:SMSmallButtonBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [self setValue:SMSmallButtonHighlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
    [self setValue:SMSmallButtonDisabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    // -1.0 on top to bring text up 1 pixel.
    [self setValue:CGInsetMake(-1.0, 5.0, 0.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];

    [self setValue:CGSizeMake(0.0, SMSmallButtonHeight) forThemeAttribute:@"min-size"];
    [self setValue:CGSizeMake(-1.0, SMSmallButtonHeight) forThemeAttribute:@"max-size"];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        var frame = [self frame];
        if (frame.size.height != SMSmallButtonHeight)
        {
            frame.size.height = SMSmallButtonHeight;
            [self setFrame:frame];
        }
    }

    return self;
}

@end
