/*
 *  HNAuthController.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright Ignacio Cases 2010. All rights reserved.
 *  Used with permission of the copyright holder.
 */

@import <Foundation/Foundation.j>

@import "../Views/HNLoginWindow.j"
@import "../Controllers/MailController.j"
@import "../ServerConnection.j"

BASE_URL = "http://localhost:3000/"; // TODO: what is this? Is it somewhere used?

var SharedController = nil;
HNUserAuthenticationDidChangeNotification = @"HNUserAuthenticationDidChangeNotification";
HNUserAuthenticationErrorNotification = @"HNUserAuthenticationErrorNotification";

@implementation HNAuthController : CPObject
{
    CPString    lastUsedUserName @accessors;
    CPString    lastUsedPassword @accessors;

    CPString    username  @accessors;
    CPString    firstName @accessors;
    CPString    password  @accessors;
    CPString    authenticationToken    @accessors;

    CPDictionary grantedUsers;
    //HNConnection conn;

    MailController mailController;
    @outlet CPWindow theWindow;
    @outlet CPImageView imageView;
    @outlet CPTextField labelTitle;
    @outlet CPTextField labelServer;
    @outlet CPTextField labelEmail;
    @outlet CPTextField labelPassword;
    @outlet CPButton buttonLogin;
    @outlet CPImageView spinner;
    @outlet CPButton flag1;
    @outlet CPButton flag2;
    @outlet CPButton flag3;
}

+ (HNAuthController)sharedController
{
    if (!SharedController)
    {
        SharedController = [[HNAuthController alloc] init];
    }
    return SharedController;
}

- (id)init
{
    if (self = [super init])
    {
        // Create the connection
        //conn = [HNConnection connectionWithRegisteredName:@"authentication" host:nil delegate:self];
        grantedUsers = [[CPDictionary alloc] init];
    }
    return self;
}

- (BOOL)isAuthenticated
{
    return [[CPUserSessionManager defaultManager] status] === CPUserSessionLoggedInStatus;
}

- (void)toggleAuthentication:(id)sender
{
    if ([self isAuthenticated])
        [self logout:sender];
    else
        [self promptForAuthentication:sender];
}

- (void)logout:(id)sender
{
    username = nil;
    authenticationToken = nil;
    firstName = nil;
    password = nil;
    //userImage = nil;
    //userThumbnailImage = nil;

    [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedOutStatus];
}

- (void)promptForAuthentication:(id)sender
{
    var loginWindow = [HNLoginWindow sharedLoginWindow];
    [loginWindow makeKeyAndOrderFront:self];
}

@end

@implementation HNAuthController (HNConnection)


- (void)authenticateWithUsername:(CPString)aUserName password:(CPString)aPassword
{
    lastUsedUserName = aUserName;
    lastUsedPassword = aPassword;
    var email = [username lowercaseString],
        serverConnection = [[ServerConnection alloc] init];

    //     host = @"mail.smartmobili.com"
    [serverConnection callRemoteFunction:@"authenticate"
     withFunctionParametersAsObject: { "userName" : aUserName, "password" : aPassword }
                        delegate:self
                  didEndSelector:@selector(imapServerAuthenticationDidChange:withParametersObject:)
                           error:nil];
}

- (void)imapServerAuthenticationDidChange: (id)sender withParametersObject:parametersObject
{
    var msg;

    if (parametersObject.status == @"SMAuthenticationGranted")
    {
        [self grantAuthentication];
    }
    else if (parametersObject.status == @"SMAuthenticationDenied")
    {
        msg = [CPDictionary dictionaryWithObject:@"User and password do not match" forKey:@"message"];
        [self updateErrorMessage:msg];
    }
    else
    {
        msg = [CPDictionary dictionaryWithObject:status forKey:@"message"];
        [self updateErrorMessage:msg];
    }
}

- (void)connection:(CPURLConnection)connection didFailWithError:(CPString)error
{
    CPLog.debug(@"error received: %@", error);
}

- (void)grantAuthentication
{
    [[CPUserSessionManager defaultManager] setStatus:CPUserSessionLoggedInStatus];
    [[CPNotificationCenter defaultCenter] postNotificationName:HNUserAuthenticationDidChangeNotification
                                                        object:nil
                                                      userInfo:nil];
}

- (void)updateErrorMessage:(id)message
{
    [[CPNotificationCenter defaultCenter] postNotificationName:HNUserAuthenticationErrorNotification
                                                        object:message
                                                      userInfo:nil];
}

@end
