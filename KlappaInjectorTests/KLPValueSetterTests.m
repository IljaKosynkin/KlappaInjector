//
//  KLPValueSetterTests.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KLPStandardValueSetter.h"

@interface InjectedClass : NSObject

@end

@implementation InjectedClass

@end

@interface TestObject : NSObject
- (BOOL) isSet;

@property InjectedClass* publicProperty;
@end

@implementation TestObject {
    InjectedClass* privateProperty;
}

- (BOOL) isSet {
    return privateProperty != nil;
}

@end

static id<KLPValueSetter> setter;
static TestObject* object;

@interface KLPValueSetterTests : XCTestCase

@end

@implementation KLPValueSetterTests

+ (void)setUp {
    setter = [[KLPStandardValueSetter alloc] init];
    object = [[TestObject alloc] init];
}

- (void) setUp {
}

- (void) testShouldSetValueForPublicProperty {
    InjectedClass* injected = [[InjectedClass alloc] init];
    [setter setValue:object forValue:injected forKey:@"publicProperty"];
    XCTAssertNotNil(object.publicProperty);
    XCTAssertTrue(object.isSet);
}

- (void) testShouldSetValueForPrivateProperty {
    InjectedClass* injected = [[InjectedClass alloc] init];
    [setter setValue:object forValue:injected forKey:@"privateProperty"];
    XCTAssertTrue(object.isSet);
}

- (void) testShouldNotThrowOnUnknownKey {
    InjectedClass* injected = [[InjectedClass alloc] init];
    [setter setValue:object forValue:injected forKey:@"bla-bla"];
    XCTAssertTrue(YES);
}

@end
