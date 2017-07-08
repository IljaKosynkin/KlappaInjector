//
//  KLPPostInjectable.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 7/8/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KLPPostInjectable <NSObject>
- (void) postInject;
@end
