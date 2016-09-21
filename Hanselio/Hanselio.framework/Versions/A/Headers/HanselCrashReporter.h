//
//  HanselCrashReporter.h
//  pebbletraceiossdk
//
//  Created by Prabodh Prakash on 25/05/16.
//  Copyright © 2016 Hansel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HanselCrashReporter : NSObject

+ (void) initializeSDKWithAppId: (NSString*) appId appKey: (NSString*) appKey;
+ (void) resync;

@end
