/*
 *  SMEditorToolbarController.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
*/

@import "../Views/SMEditorToolbarView.j"

var SMEditorToolbarControllerFontSizes = [10, 13, 16, 18, 24, 32, 48];

/**
    Control the toolbar with editor formatting options.
*/
@implementation SMEditorToolbarController : CPViewController
{
    IBOutlet CPView             editorToolbarContentView;

    IBOutlet CPPopUpButton      fontPopUp;
    IBOutlet CPPopUpButton      sizePopUp;

    IBOutlet CPSegmentedControl colorSegment;

    IBOutlet CPSegmentedControl styleSegment;
    IBOutlet CPSegmentedControl alignSegment;
    IBOutlet CPSegmentedControl listSegment;

    CPArray                     availableFonts;
    IBOutlet WKTextView         textView @accessors;
}

- (void)awakeFromCib
{
    availableFonts = [[CPFontManager sharedFontManager] availableFonts];
    for (var i = 0, count = [availableFonts count]; i < count; i++)
    {
        var fontName = availableFonts[i],
            menuItem = [[CPMenuItem alloc] initWithTitle:fontName action:nil keyEquivalent:nil];
        [fontPopUp addItem:menuItem];
    }

    for (var i = 0, count = [SMEditorToolbarControllerFontSizes count]; i < count; i++)
    {
        var size = SMEditorToolbarControllerFontSizes[i],
            menuItem = [[CPMenuItem alloc] initWithTitle:String(size) action:nil keyEquivalent:nil];
        [sizePopUp addItem:menuItem];
    }
    [sizePopUp selectItemWithTitle:"12"];
}

- (IBAction)styleButtonClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        case 0: [CPApp sendAction:@selector(boldSelection:) to:textView from:self]; break;
        case 1: [CPApp sendAction:@selector(italicSelection:) to:textView from:self]; break;
        case 2: [CPApp sendAction:@selector(underlineSelection:) to:textView from:self]; break;
    }
}

- (IBAction)alignButtonClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        case 0: [CPApp sendAction:@selector(alignSelectionLeft:) to:textView from:self]; break;
        case 1: [CPApp sendAction:@selector(alignSelectionCenter:) to:textView from:self]; break;
        case 2: [CPApp sendAction:@selector(alignSelectionRight:) to:textView from:self]; break;
        case 3: [CPApp sendAction:@selector(alignSelectionFull:) to:textView from:self]; break;
    }
}

- (IBAction)listButtonClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        case 0: [CPApp sendAction:@selector(insertUnorderedList:) to:textView from:self]; break;
        case 1: [CPApp sendAction:@selector(insertOrderedList:) to:textView from:self]; break;
    }
}

- (IBAction)colorButtonClicked:(id)sender
{
    switch ([sender selectedSegment])
    {
        // TODO Open colour picker.
    }
}

- (IBAction)doFont:(id)sender
{
    var fontName = [sender titleOfSelectedItem];
    [textView setFontNameForSelection:fontName];
}

- (IBAction)doFontSize:(id)sender
{
    var fontSize = parseInt([sender titleOfSelectedItem]);
    for (var i = 0; i < SMEditorToolbarControllerFontSizes.length; i++)
    {
        if (SMEditorToolbarControllerFontSizes[i] == fontSize)
            [textView setFontSizeForSelection:1 + i];
    }
}

@end
