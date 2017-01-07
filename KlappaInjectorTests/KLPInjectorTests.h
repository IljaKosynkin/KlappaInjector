//
//  KLPInjectorTests.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 1/7/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPInjectorTests_h
#define KLPInjectorTests_h

#import "KLPStandardInjector.h"

@protocol TestProtocol <NSObject>

@end

@interface InjectedClass2 : NSObject<TestProtocol>

@end

@implementation InjectedClass2
@end

@interface InjectedClass3 : NSObject

@end

@implementation InjectedClass3
@end

@interface InjectedClass4 : NSObject

@end

@implementation InjectedClass4
@end

@interface InjectedClass5 : InjectedClass4

@end

@implementation InjectedClass5
@end

@interface TestObject2 : NSObject
@property InjectedClass2* injectedPropertyNoLimit;
@property InjectedClass3* injectedPropertyLimited;
@end

@implementation TestObject2
@end

@interface TestObject3 : NSObject
@property InjectedClass2* injectedPropertyNoLimit;
@property InjectedClass4* injectedPropertyFirst;
@property InjectedClass4* injectedPropertySecond;
@end

@implementation TestObject3
@end

@interface TestObject4 : NSObject
@property InjectedClass3* injectedPropertyLimited;
@end

@implementation TestObject4
@end

@interface TestObject5 : TestObject2
@end

@implementation TestObject5
@end

@interface TestObject6 : UIView
@property InjectedClass2* injectedPropertyNoLimit;
@end

@implementation TestObject6
@end

@interface TestObject7 : NSObject
@property NSObject<TestProtocol>* injectedPropertyProtocol;
@property InjectedClass4* injectedPropertyBaseClass;
@end

@implementation TestObject7
@end

static TestObject2* object2;
static TestObject3* object3;
static TestObject4* object4;
static TestObject5* object5;
static TestObject6* object6;
static TestObject7* object7;

static KLPStandardInjector* injector;
#endif /* KLPInjectorTests_h */
