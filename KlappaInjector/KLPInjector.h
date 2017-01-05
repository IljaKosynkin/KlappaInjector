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

@protocol KLPInjector <NSObject>
- (id<KLPInjector>)registerInjectable:(id)object forType:(Class)type withId:(NSString*)identifier;
- (void)inject:(id)into;
@end

#endif
