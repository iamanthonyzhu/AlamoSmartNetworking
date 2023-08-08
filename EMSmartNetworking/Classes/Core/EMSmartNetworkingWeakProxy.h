//
//  EMSmartNetworkingWeakProxy.h
//  EMSmartNetworking
//
//  Created by Aron.li on 2020/8/7.
//

#import <Foundation/Foundation.h>


@interface EMSmartNetworkingWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype _Nullable)initWithTarget:(id _Nullable )target;

+ (instancetype _Nullable )proxyWithTarget:(id _Nullable )target;

@end
