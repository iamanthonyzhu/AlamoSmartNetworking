//
//  NZNetworkingConfiguration.h
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//


@interface NZNetworkingConfiguration:NSObject

+ (instancetype)sharedInstance;

#pragma mark - 设置头部信息
/**
 *  设置头信息
 *
 *  @param value 值
 *  @param key   键
 */
- (void)setHeader:(NSString *)value forKey:(NSString *)key;

/**
 *  移除头健值信息
 *
 *  @param key   键
 */
- (void)removeHeaderForKey:(NSString *)key;

@end
