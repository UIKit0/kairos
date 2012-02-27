/*
 *  SMUploadToolbarItem.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

@import "../Components/FileUpload.j" // UploadButton component.

/*!
    A toolbar item which places an upload button on top of itself.
*/
@implementation SMUploadToolbarItem : CPToolbarItem
{
    CPView uploadView;
    CPView imageView;
}

- (id)initWithItemIdentifier:(CPString)anItemIdentifier
{
    if (self = [super initWithItemIdentifier:anItemIdentifier])
    {
        [self _init];
    }

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
    }

    return self;
}

- (void)_init
{
    uploadView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    var bounds = [uploadView bounds];
    imageView = [[CPImageView alloc] initWithFrame:bounds];

    [imageView setImageScaling:CPScaleProportionally];
    [imageView setImage:[self image]];
    [imageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable]
    [uploadView addSubview:imageView];

    var fileUploadButton = [[UploadButton alloc] initWithFrame:bounds];
    [fileUploadButton setBordered:NO];
    [fileUploadButton allowsMultipleFiles:YES];
    [fileUploadButton setURL:"uploadAttachment"];
    [fileUploadButton setDelegate:self];

    [uploadView addSubview:fileUploadButton];
}

- (void)setImage:(CPImage)anImage
{
    [super setImage:anImage];
    [imageView setImage:[self image]];
}

- (CPView)view
{
    return uploadView;
}

#pragma mark -
#pragma mark UploadButton Handlers

- (void)uploadButton:(UploadButton)button didChangeSelection:(CPArray)selection
{
    [button submit];
}

- (void)uploadButton:(UploadButton)button didFailWithError:(CPString)anError
{
    alert("Upload failed with this error: " + anError);
     // TODO for GUI developer: hide loading indicator (e.g. ajax-loader.gif)
}

- (void)uploadButton:(UploadButton)button didFinishUploadWithData:(CPString)response
{
    [button resetSelection];
    [CPApp sendAction:[self action] to:[self target] from:self];
    // TODO for GUI developer: hide loading indicator (e.g. ajax-loader.gif)
}

- (void)uploadButtonDidBeginUpload:(UploadButton)button
{
    // TODO for GUI developer: show loading indicator (e.g. ajax-loader.gif)
}

@end
