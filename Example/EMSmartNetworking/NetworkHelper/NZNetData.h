//
//  EatNetData.h
//  BaseApp
//
//  Created by Infzm on 15/3/27.
//  Copyright (c) 2015年 sunima. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NZNetworkEnvelopProtocol.h"


static NSString *const NZNetDataBadNetMsg   = @"加载失败，请检查网络";
static NSInteger const NZNetDataBadNetCode  = 400;
static NSString *const NZNetDataBadNetRetryMsg = @"网络不给力，请检查后再试";
static NSString *const NZNetErrorMsg = @"网络不给力";

static NSString *const NZNetSessionErrMsg   = @"登录超时，请重新登录";
static NSInteger const NZNetSessionErrCode  = 419;
static NSString *const NZNetDataErrorSalt   = @"600";

static NSString *const NZNetDataErrorMsg    = @"加载失败，请检查网络";
static NSInteger const NZNetDataErrorCode   = 500;

static NSInteger const NZNetDataSuccess     = 200;

@interface NZNetData : NSObject<NZNetworkEnvelopProtocol>

@property(nonatomic, assign)  NSInteger code;
@property(nonatomic, copy) NSString * msg;
@property(nonatomic, strong) NSError * error;
@property(nonatomic, strong) id rawData;
@property(nonatomic, strong) id data;
@property(nonatomic, strong) id bizModel;

+ (id)netdataWithObject:(id)object;
+ (id)badNetData;
+ (id)errorData:(NSError *)error;
+ (id)sessionError;
- (id)getRawData;

@end
