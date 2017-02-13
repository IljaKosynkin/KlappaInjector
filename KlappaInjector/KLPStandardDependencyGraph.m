//
//  KLPStandardDependencyGraph.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/5/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import "KLPStandardDependencyGraph.h"
#import <objc/runtime.h>

@implementation KLPStandardDependencyGraph {
    NSMutableDictionary* dependentObjects;
}

- (instancetype)init {
    self = [super init];
    dependentObjects = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) registerObject:(id) dependentObject encodedType:(NSString*) encodedType forField:(NSString*) field {
    KLPDependentObject* dependent = [[KLPDependentObject alloc] init];
    dependent.object = dependentObject;
    dependent.fieldName = field;
    
    if (dependentObjects[encodedType] == nil) {
        dependentObjects[encodedType] = [[NSMutableArray alloc] init];
    }
        
    NSMutableArray* depObjs = dependentObjects[encodedType];
    [depObjs addObject:dependent];
}

- (void) registerDependency:(id) dependency forClass:(Class) mainClass forField:(NSString*) name {
    Class objectClass = mainClass;

    KLPDependentObject* dependent = [[KLPDependentObject alloc] init];
    dependent.object = dependency;
    dependent.fieldName = name;
    
    unsigned count;
    __unsafe_unretained Protocol **pl;
    
    do {
        NSString* key = NSStringFromClass(objectClass);
        if (dependentObjects[key] == nil) {
            dependentObjects[key] = [[NSMutableArray alloc] init];
        }
        
        NSMutableArray* depObjs = dependentObjects[key];
        [depObjs addObject:dependent];
     
        pl = class_copyProtocolList(objectClass, &count);
        for (unsigned i = 0; i < count; i++) {
            NSString* protocolName = [NSString stringWithUTF8String: protocol_getName(pl[i])];
            if (dependentObjects[protocolName] == nil) {
                dependentObjects[protocolName] = [[NSMutableArray alloc] init];
            }
            
            NSMutableArray* depObjs = dependentObjects[protocolName];
            [depObjs addObject:dependent];
        }
            
        free(pl);
        
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && objectClass != nil);
}

- (NSArray*) getDependentObjects:(Class) forClass {
    NSMutableArray* objects = [[NSMutableArray alloc] init];
    
    Class objectClass = forClass;
    unsigned count;
    __unsafe_unretained Protocol **pl;
    do {
        NSString* key = NSStringFromClass(objectClass);
        NSMutableArray* depObjects = dependentObjects[key];
        
        NSMutableArray* fieldsToRemove = [[NSMutableArray alloc] init];
        for (KLPDependentObject* depObj in depObjects) {
            if (depObj.object == nil) {
                [fieldsToRemove addObject:depObj];
                continue;
            }
            
            [objects addObject:depObj];
        }
        
        pl = class_copyProtocolList(objectClass, &count);
        for (unsigned i = 0; i < count; i++) {
            NSString* protocolName = [NSString stringWithUTF8String: protocol_getName(pl[i])];
            NSMutableArray* depObjects = dependentObjects[protocolName];
            
            for (KLPDependentObject* depObj in depObjects) {
                if (depObj.object == nil) {
                    [fieldsToRemove addObject:depObj];
                    continue;
                }
                
                [objects addObject:depObj];
            }
        }
        
        free(pl);
        
        [depObjects removeObjectsInArray:fieldsToRemove];
        
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && objectClass != nil);

    return objects;
}
@end
