//
//  KLPInjector.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/15/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPStandardInjector_h
#define KLPStandardInjector_h

#import <Foundation/Foundation.h>
#import "KLPStandardValueSetter.h"
#import "KLPInjector.h"
#import "KLPDependencyGraph.h"

@interface KLPStandardInjector : NSObject<KLPInjector>

- (void)inject:(id)into;
- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier explicitRegistration:(BOOL)explicitRegistration;

- (void) addExcludedClass:(Class) excluded;

- (void) setValueSetter:(id<KLPValueSetter>)setter;
- (void) setDependencyGraph:(id<KLPDependencyGraph>) graph;
- (void) setDependencyTracking:(BOOL) active forClass:(Class) objectType explicit:(BOOL) explicitTracking;

- (void) reinjectObjectIntoDependentObjects:(Class) objectType explicitReinjection:(BOOL) explicitReinjection;
@end

#endif
