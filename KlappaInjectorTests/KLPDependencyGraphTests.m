//
//  KLPDependencyGraphTests.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/11/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KLPStandardDependencyGraph.h"


@interface KLPTestMainObject : NSObject

@end

@implementation KLPTestMainObject

@end

@interface KLPTestDependentObject : NSObject
@property KLPTestMainObject* mainObject;
@end

@implementation KLPTestDependentObject

@end

static KLPStandardDependencyGraph* graph;
static KLPTestMainObject* mainObject;
static KLPTestDependentObject* dependentObject;

@interface KLPDependencyGraphTests : XCTestCase

@end

@implementation KLPDependencyGraphTests

+ (void)setUp {
    
    graph = [[KLPStandardDependencyGraph alloc] init];
    mainObject = [[KLPTestMainObject alloc] init];
    dependentObject = [[KLPTestDependentObject alloc] init];
    
    [graph registerDependency:dependentObject forClass: [KLPTestMainObject class] forField:@"mainObject"];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testShouldRegisterObject {
    NSArray* dependecies = [graph getDependentObjects:[KLPTestMainObject class]];
    
    XCTAssertEqual([dependecies count], 1);
    
    KLPDependentObject* obj = [dependecies objectAtIndex:0];
    XCTAssertEqual(obj.object, dependentObject);
    XCTAssertEqual(obj.fieldName, @"mainObject");
}

- (void) registerWithDealloc {
    KLPTestDependentObject* dependentObject = [[KLPTestDependentObject alloc] init];
    
    [graph registerDependency:dependentObject forClass: [KLPTestMainObject class] forField:@"temporaryField"];
}

- (void) testShouldNotHoldObject {
    [self registerWithDealloc];
    
    NSArray* dependecies = [graph getDependentObjects:[KLPTestMainObject class]];
    
    XCTAssertEqual([dependecies count], 1);
    
    KLPDependentObject* obj = [dependecies objectAtIndex:0];
    XCTAssertEqual(obj.object, dependentObject);
    XCTAssertEqual(obj.fieldName, @"mainObject");
}

@end
