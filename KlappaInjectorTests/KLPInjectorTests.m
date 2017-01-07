//
//  KLPInjectorTests.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KLPInjectorTests.h"


@interface KLPInjectorTests : XCTestCase

@end

@implementation KLPInjectorTests

+ (void)setUp {
    object2 = [[TestObject2 alloc] init];
    object3 = [[TestObject3 alloc] init];
    object4 = [[TestObject4 alloc] init];
    object5 = [[TestObject5 alloc] init];
    object6 = [[TestObject6 alloc] init];
    object7 = [[TestObject7 alloc] init];
    
    injector = [[KLPStandardInjector alloc] init];
    
    InjectedClass2* class2 = [[InjectedClass2 alloc] init];
    InjectedClass3* class3 = [[InjectedClass3 alloc] init];
    InjectedClass4* class41 = [[InjectedClass4 alloc] init];
    InjectedClass4* class42 = [[InjectedClass4 alloc] init];
    InjectedClass5* class5 = [[InjectedClass5 alloc] init];
    
    Class testClass2 = [TestObject2 class];
    Class testClass3 = [TestObject3 class];
    
    [injector registerInjectable:class2 forType:nil withId:nil explicitRegistration:YES];
    [injector registerInjectable:class5 forType:nil withId:nil explicitRegistration:YES];
    [injector registerInjectable:class3 forType:&testClass2 withId:nil explicitRegistration:YES];
    [injector registerInjectable:class41 forType:&testClass3 withId:@"first" explicitRegistration:YES];
    [injector registerInjectable:class42 forType:&testClass3 withId:@"second" explicitRegistration:YES];
}

- (void) setUp {
    object2.injectedPropertyLimited = nil;
    object2.injectedPropertyNoLimit = nil;
    
    object3.injectedPropertyFirst = nil;
    object3.injectedPropertySecond = nil;
    object3.injectedPropertyNoLimit = nil;
    
    object4.injectedPropertyLimited = nil;
    
    object5.injectedPropertyLimited = nil;
    object5.injectedPropertyNoLimit = nil;
    
    object6.injectedPropertyNoLimit = nil;
    
    object7.injectedPropertyProtocol = nil;
    object7.injectedPropertyBaseClass = nil;
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


- (void) testShouldThrowOnInjectionToUnregisteredObject {
    XCTAssertThrows([injector inject:object4]);
}

- (void) testShouldSetAncestorProperties {
    [injector inject:object5];
    
    XCTAssertNotNil(object5.injectedPropertyNoLimit);
    XCTAssertNotNil(object5.injectedPropertyLimited);
}

- (void) testShouldSetPropertiesOnViewDescendant {
    [injector inject:object6];
    
    XCTAssertNotNil(object6.injectedPropertyNoLimit);
}

- (void) testShouldSetToProtocolFieldAndBaseClass {
    [injector inject:object7];
    
    XCTAssertNotNil(object7.injectedPropertyProtocol);
    XCTAssertNotNil(object7.injectedPropertyBaseClass);
}

/*
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

- (void) testInjection {
    [self measureBlock:^{
        for (int i = 0; i < 10000; i++) {
            [injector inject:object2];
        }
    }];
}
*/

@end
