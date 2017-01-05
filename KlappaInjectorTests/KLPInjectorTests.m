//
//  KLPInjectorTests.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KLPStandardInjector.h"

@interface InjectedClass2 : NSObject

@end

@implementation InjectedClass2
+ (NSString*) getType {
    return NSStringFromClass([InjectedClass2 class]);
}
@end

@interface InjectedClass3 : NSObject

@end

@implementation InjectedClass3
+ (NSString*) getType {
    return NSStringFromClass([InjectedClass3 class]);
}
@end

@interface InjectedClass4 : NSObject

@end

@implementation InjectedClass4
+ (NSString*) getType {
    return NSStringFromClass([InjectedClass4 class]);
}
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

static TestObject2* object2;
static TestObject3* object3;
static TestObject4* object4;
static KLPStandardInjector* injector;

@interface KLPInjectorTests : XCTestCase

@end

@implementation KLPInjectorTests

+ (void)setUp {
    object2 = [[TestObject2 alloc] init];
    object3 = [[TestObject3 alloc] init];
    object4 = [[TestObject4 alloc] init];
    injector = [[KLPStandardInjector alloc] init];
    
    InjectedClass2* class2 = [[InjectedClass2 alloc] init];
    InjectedClass3* class3 = [[InjectedClass3 alloc] init];
    InjectedClass4* class41 = [[InjectedClass4 alloc] init];
    InjectedClass4* class42 = [[InjectedClass4 alloc] init];
    
    Class testClass2 = [TestObject2 class];
    Class testClass3 = [TestObject3 class];
    
    [injector registerInjectable:class2 forType:nil withId:nil];
    [injector registerInjectable:class3 forType:&testClass2 withId:nil];
    [injector registerInjectable:class41 forType:&testClass3 withId:@"first"];
    [injector registerInjectable:class42 forType:&testClass3 withId:@"second"];
}

- (void) setUp {
    object2.injectedPropertyLimited = nil;
    object2.injectedPropertyNoLimit = nil;
    
    object3.injectedPropertyFirst = nil;
    object3.injectedPropertySecond = nil;
    object3.injectedPropertyNoLimit = nil;
}

- (void) testShouldSetPropertyWithNoLimit {
    [injector inject:object2];
    [injector inject:object3];
    
    XCTAssertNotNil(object2.injectedPropertyNoLimit);
    XCTAssertNotNil(object3.injectedPropertyNoLimit);
}

- (void) testShouldSetPropertyWithIDs {
    [injector inject:object3];
    XCTAssertNotNil(object3.injectedPropertyFirst);
    XCTAssertNotNil(object3.injectedPropertySecond);
}

- (void)testStraightAssignement {
    InjectedClass2* class2 = [[InjectedClass2 alloc] init];
    InjectedClass3* class3 = [[InjectedClass3 alloc] init];
    
    [self measureBlock:^{
        for (int i = 0; i < 10000; i++) {
            object2.injectedPropertyNoLimit = class2;
            object2.injectedPropertyLimited = class3;
        }
    }];
}

- (void) testShouldThrowOnInjectionToUnregisteredObject {
    XCTAssertThrows([injector inject:object4]);
}

- (void) testInjection {
    [self measureBlock:^{
        for (int i = 0; i < 10000; i++) {
            [injector inject:object2];
        }
    }];
}

@end
