//
//  HanselSwiftTypeWrapper.h
//  Hanselio
//
//  Created by Prabodh Prakash on 11/01/17.
//  Copyright © 2017 Hansel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HanselSwiftTypeWrapper : NSObject

@property (nonatomic) id object;
@property (nonatomic) NSString* className;

-(instancetype)initWithObject:(id)object className:(NSString*)className;
- (id) getObject;
- (NSString*) getClassName;

@end
