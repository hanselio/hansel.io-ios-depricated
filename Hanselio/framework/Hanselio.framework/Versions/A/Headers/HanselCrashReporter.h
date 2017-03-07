//
//  HanselCrashReporter.h
//  pebbletraceiossdk
//
//  Created by Prabodh Prakash on 25/05/16.
//  Copyright © 2016 Hansel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface HanselCrashReporter : NSObject

+ (void) initializeSDKWithAppId: (NSString*) appId appKey: (NSString*) appKey;
+ (void) resync;
+ (BOOL) isPatchEnabled: (NSString*) functionString;
+ (JSValue*) invokePatchWithArgumentsArray: (NSArray*) arr modifierArray: (NSArray*) modArr classArr: (NSArray*) classArr className: (NSString*) className functionName: (NSString*) functionName closure: (id (^)(NSArray* arr))closure callAnythingClosure: (id (^)(NSArray*))callAnythingClosure selfRef: (id) selfRef;
+ (void) evaluateJavascript: (NSString*) patch;
+ (id) tryUnwrapping:(id) boxedObject;

@end
