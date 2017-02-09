//
//  KLPStandardDependencyGraph.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/5/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import "KLPStandardDependencyGraph.h"

@interface KLPDependentObject : NSObject
@property(weak) id object;
@end

@implementation KLPDependentObject

@end

@implementation KLPStandardDependencyGraph {
    NSMutableDictionary* dependentObjects;
}

- (instancetype)init {
    self = [super init];
    dependentObjects = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) registerDependency:(id) dependency forClass:(Class) mainClass forField:(NSString*) name {
    Class objectClass = mainClass;

    KLPDependentObject* dependent = [[KLPDependentObject alloc] init];
    dependent.object = dependency;
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[name] = dependent;
    
    do {
        NSString* key = NSStringFromClass(objectClass);
        if (dependentObjects[key] == nil) {
            dependentObjects[key] = [[NSMutableDictionary alloc] init];
        }
        
        dependentObjects[key][name] = dependent;
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && objectClass != nil);
}

- (NSDictionary*) getDependentObjects:(Class) forClass {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    Class objectClass = forClass;
    do {
        NSString* key = NSStringFromClass(objectClass);
        NSMutableDictionary* depObjects = dependentObjects[key];
        NSMutableArray* fieldsToRemove = [[NSMutableArray alloc]
                                          init];
        for (NSString* fieldName in depObjects) {
            KLPDependentObject* depObj = depObjects[fieldName];
            if (depObj.object == nil) {
                [fieldsToRemove addObject:fieldName];
                continue;
            }
            
            NSString* newKey = [[key stringByAppendingString:separator] stringByAppendingString:fieldName];
            dict[newKey] = depObj.object;
        }
        
        for (NSString* fieldName in fieldsToRemove) {
            depObjects[fieldName] = nil;
        }
        
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && objectClass != nil);

    return dict;
}
@end
