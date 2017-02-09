//
//  KLPInjector.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPInjector_h
#define KLPInjector_h

#import <Foundation/Foundation.h>
#import "KLPDependencyGraph.h"

@protocol KLPInjector <NSObject>
- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*) type withId:(NSString*) identifier explicitRegistration:(BOOL) explicitRegistration;
- (void)inject:(id)into;
- (void) setDependencyTracking:(BOOL) active forClass:(Class) objectType explicit:(BOOL) explicitTracking;
- (void) setDependencyGraph:(id<KLPDependencyGraph>) graph;
- (void) reinjectObjectIntoDependentObjects:(Class) objectType explicitReinjection:(BOOL) explicitReinjection;
@end

#endif
