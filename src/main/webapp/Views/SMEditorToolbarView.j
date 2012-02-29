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
    SMEditorToolbarViewBackgroundColor = CPColorWithImages([
        nil,
        ['editor-toolbar-bezel.png', 167, 29],
        nil
    ]);
}

- (void)_init
{
    [self setBackgroundColor:SMEditorToolbarViewBackgroundColor];
}

- (void)awakeFromCib
{
    [self _init];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
    }
    return self;
}

@end

