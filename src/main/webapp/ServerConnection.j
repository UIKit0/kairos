/*
 *  AppController.j
 *  Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>


@implementation ServerConnection : CPObject
{
    id              _delegate;
    SEL             _didEndSelector;
    SEL             _errorSelector;
    CPString        _accumulatedResponseString;
    int             _statusCode;
    int             _responsesCount;
    CPTimer         _timerTimeoutWaitingResponse;
    var             _urlConnection;
    var             _timeoutInSeconds;
}

- (id)init
{
    if (self = [super init])
    {
        [self setDefaultTimeout];
    }
    return self;
}

#pragma mark -
#pragma mark Other

// works only for new requests. Old processing will use old value.
-(void)setTimeout:(int)timoutInSeconds
{
    _timeoutInSeconds = timoutInSeconds;
}

-(void)setDefaultTimeout
{
    _timeoutInSeconds = 35;
}



#pragma mark -
#pragma mark CPURLConnecion 
-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    // This will be newer called during normal operation, even if server is not responded.
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response
{
    _responsesCount = _responsesCount + 1;
    _accumulatedResponseString = [[CPString alloc] initWithString:@""];
    _statusCode = [response statusCode];
    if (_statusCode != 0)
    {
        // We got response, stop the timeout timer:
        [_timerTimeoutWaitingResponse invalidate]; //stop
    }
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    // We accumulate through several (possible) calls of didReceiveData
    _accumulatedResponseString = [_accumulatedResponseString stringByAppendingString:data];
}

-(void)connectionDidFinishLoading:(CPURLConnection)connection
{
    // This is FIX for firefox (when calling URLConnection, first response is with status 0 and with useless didReceiveData and connectionDidFinishLoading calls.
    // Note that if _statusCode == 0 this not means error in Firefox. This means nothing, perhaps there is will be another response soon...
    // But in all browsers 0 means that current data is not a data. In WebKit 
    // if 0 of course this means error in connection. In Firefox this means nothing.
    if (_statusCode == 0)
        return;
    
    // calling event of data did recieved
    if (_delegate)
        if (_didEndSelector)
        {
            var jsObject = [_accumulatedResponseString objectFromJSON];
            objj_msgSend(_delegate, _didEndSelector, self, jsObject);

        }
    }
}

- (void)timerTimeoutWaitingResponseTick:(var)anParam
{
    [_urlConnection cancel];
    if (_delegate)
        if (_errorSelector)
        {
            objj_msgSend(_delegate, _errorSelector, self);
        }
    }
}

#pragma mark -
#pragma mark Commands From Client to Server
/*
 * "aError" is a selector which will be called when connection is failed, 
 * for example if remote server is not responding. So it will be called, when
 * ServerConnection failed to "call" requested "function" from server.
 */
- (void) callRemoteFunction:(CPString)functionNameToCall withFunctionParametersAsObject:functionParametersInObject delegate:(id)aDelegate didEndSelector:(SEL)aSelector error:(SEL)aError
{
    _statusCode = 0;
    _responsesCount = 0;
    _delegate = aDelegate;
    _didEndSelector = aSelector;
    _errorSelector = aError;
    if (!_urlConnection)
        [_urlConnection cancel];
    if (!_timerTimeoutWaitingResponse)
        [_timerTimeoutWaitingResponse invalidate]; //stop
    
    var request = [[CPURLRequest alloc] initWithURL:@"postRequest"]; // TODO: need add random subparameter to avoid caching ?
    [request setHTTPMethod:@"POST"]; 
    
    var functionParametersInJSON = nil;
    if (functionParametersInObject)
        functionParametersInJSON = [CPString JSONFromObject:functionParametersInObject];
    var jsonObjectToPost = { "functionNameToCall" : functionNameToCall,
        "functionParameters"  : functionParametersInJSON };
    
    [request setHTTPBody:[CPString JSONFromObject:jsonObjectToPost]];
    
    _urlConnection = [CPURLConnection connectionWithRequest:request delegate:self];
    
    // This require a lot of memory - a new timer for each request! But there is no good way to solve Firefox issue with URLConnection and POST command which is not return responce 200 from first time, which can be 0 (NS_BINDING_ABORTED). (See more comments in function connectionDidFinishLoading above).
    _timerTimeoutWaitingResponse = [CPTimer scheduledTimerWithTimeInterval:_timeoutInSeconds  // timeout in seconds to raise timeout (_errorSelector).
                                     target:self
                                   selector:@selector(timerTimeoutWaitingResponseTick:)
                                   userInfo:nil
                                    repeats:NO];
    
    [_urlConnection start];
}

@end