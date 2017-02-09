//
//  KLPStandardDependencyGraph.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/5/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KLPDependencyGraph.h"

static NSString* separator = @"|_+_|";

@interface KLPStandardDependencyGraph : NSObject<KLPDependencyGraph>
- (void) registerDependency:(id) dependency forClass:(Class) mainClass forField:(NSString*) name;
- (NSDictionary*) getDependentObjects:(Class) objectClass;
@end
