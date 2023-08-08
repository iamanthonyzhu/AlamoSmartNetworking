//
//  EMSmartNetworkingWeakProxy.h
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EMSmartNetworkingWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype _Nullable)initWithTarget:(id _Nullable )target;

+ (instancetype _Nullable )proxyWithTarget:(id _Nullable )target;

@end
