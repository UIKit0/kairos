/*
 *  SMEditorToolbarView.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

var SMEditorToolbarViewBackgroundColor;

@implementation SMEditorToolbarView : CPView
{
}

+ (void)initialize
{
    console.log("initialize");
    SMEditorToolbarViewBackgroundColor = CPColorWithImages([
        nil,
        ['editor-toolbar-bezel.png', 167, 29],
        nil
    ]);
}

- (void)_init
{
    console.log("_init", SMEditorToolbarViewBackgroundColor);
    [self setBackgroundColor:SMEditorToolbarViewBackgroundColor];
}

- (void)awakeFromCib
{
    console.log("awakeFromCib");
    [self _init];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        console.log("initWithCoder");
        [self _init];
    }
    return self;
}

@end

