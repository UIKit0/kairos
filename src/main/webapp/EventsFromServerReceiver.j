/*
 *  EventsFromServerReceiver
 *  Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 * 
 *  TODO: This class should be later remade to COMET connection to recieve events from server.
 */

@import <AppKit/AppKit.j>


@implementation EventsFromServerReceiver : CPObject
{
    id              _delegate;
    SEL             _eventOccurredSelector;
    var             _serverConnection;
    var             _authenticationController;
    var             _mailController;
}

- (void)initWithAuthenticationController:(HNAuthController)authenticationController withDelegate:(id)aDelegate withEventOccurredSelector:(SEL)aSelector
                     withMailController:(MailController)aMailController;
{
    _serverConnection = [[ServerConnection alloc] init];
    _delegate = aDelegate;
    _eventOccurredSelector = aSelector;
    _authenticationController = authenticationController;
    _mailController = aMailController;
    return self;
}

- (void)start
{
    // TODO: currently usual timer and usual get request (via ServerConnection) used.
    [self startTimer];
}

- (void)timerTick:(var)aMailbox
{
    if ([_authenticationController isAuthenticated]) // if we not authenticated, then login window should be shown so we should not "tick" here.
    {
        [_serverConnection callRemoteFunction:@"getEventsAndTestSessionValidSoKeepAlive"
               withFunctionParametersAsObject:nil
                                     delegate:self
                               didEndSelector:@selector(getEventsAndTestSessionValidSoKeepAliveDidReceived:withParametersObject:)
                                        error:@selector(getEventsAndTestSessionValidSoKeepAliveDidReceivedError:)];
        //  "getEventsAndTestSessionValidSoKeepAliveDidReceivedError" used so: if error in connection, then it show an floating warning.
    }
}

-(void)AnEventOccured_TellItForOtsideWorld:(CPString)data // TODO: unused yet (will be when some events will be recieved from server.
{
    if (_delegate)
        if (_didEndSelector)
        {
            var jsObject = [data objectFromJSON];
                 objj_msgSend(_delegate, _didEndSelector, self, jsObject);
        }
}


- (void)getEventsAndTestSessionValidSoKeepAliveDidReceived:(id)sender withParametersObject:parametersObject 
{
    if (parametersObject.credentialsIsValidInSession == false)
    {
          // try to authenticate with old login and password.
        // THINK: perhaps we should not use direct call authenticate to server? (We have HNAuthController for this? BUt HNAuthController has different delegate and selectors. Here we handle it to re-start timer or show login window for user.
        [_serverConnection callRemoteFunction:@"authenticate"
              withFunctionParametersAsObject: { "userName" : [_authenticationController lastUsedUserName], "password" : [_authenticationController lastUsedPassword] }
                                    delegate:self
                              didEndSelector:@selector(imapServerAuthenticationDidChange:withParametersObject:)
                                       error:nil];
    }
    else
    {
        [_mailController setErrorInConnectionFloatingWindowVisible:false];
        // restart timer
        [self startTimer];
    }
}

-(void)getEventsAndTestSessionValidSoKeepAliveDidReceivedError:(id)sender
{
    [_mailController setErrorInConnectionFloatingWindowVisible:true];
    [self startTimer];
}

- (void)startTimer
{
    [CPTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(timerTick:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)imapServerAuthenticationDidChange:(id)sender withParametersObject:parametersObject
{
    if (parametersObject.status == @"SMAuthenticationGranted")
    {
        [self startTimer];
    }
    else if (parametersObject.status == @"SMAuthenticationDenied")
    {
        // Even old pass and login authentication failed. Seems like login and pass changed on server. Show login window.
        [_authenticationController logout:nil];
        // TODO: // UNDONE: after logging-in start timer !
        alert("UNDONE: not yet implemented. Should restart timer of EventsFromServerReceiver"); // TODO: note we can't just start here, we should start only after success of auth.
        // TODO: UNDONE: [_authenticationController promptForAuthentication]; //  just call to promt for auth is not VALID:  timer will not be restarted. Perhaps need always start timer only after auth completed in login window? (not from MailController.
    }
    else
    {
        // THINK: // TODO:
    }
}

@end