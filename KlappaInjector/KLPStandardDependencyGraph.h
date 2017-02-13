//
//  KLPStandardDependencyGraph.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/5/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KLPDependencyGraph.h"
#import "KLPDependentObject.h"

static NSString* separator = @"|_+_|";

@interface KLPStandardDependencyGraph : NSObject<KLPDependencyGraph>
- (void) registerObject:(id) dependentObject encodedType:(NSString*) encodedType forField:(NSString*) field;
- (void) registerDependency:(id) dependency forClass:(Class) mainClass forField:(NSString*) name;
- (NSArray*) getDependentObjects:(Class) forClass;
@end
