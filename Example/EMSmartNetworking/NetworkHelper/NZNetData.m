//
//  EatNetData.m
//  BaseApp
//
//  Created by Infzm on 15/3/27.
//  Copyright (c) 2015年 sunima. All rights reserved.
//

#import "NZNetData.h"
#import <YYModel/NSObject+YYModel.h>

static NSString *const NZNetDataKey = @"rawData";

@implementation NZNetData

+ (id)netdataWithObject:(id)object
{
    NZNetData *data = [[NZNetData alloc] init];
    if (object) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            data = [NZNetData yy_modelWithDictionary:object];
        } else {
            data = [NZNetData yy_modelWithDictionary:@{NZNetDataKey:object}];
        }
    } else {
        data.code = 0;
        data.msg = nil;
    }
    return data;
}

+ (id)badNetData
{
    NZNetData *data = [self netdataWithObject:nil];
    data.code = NZNetDataBadNetCode;
    data.msg = NZNetDataBadNetMsg;
    return data;
}

+ (id)errorData:(NSError *)error
{
    NZNetData *data = [self netdataWithObject:nil];
    data.error = error;
    data.code = NZNetDataBadNetCode;
    data.msg = NZNetErrorMsg;
    
    if ([error.domain isEqualToString:NZNetDataErrorSalt]) {
        data.code = [NZNetDataErrorSalt intValue];
        data.msg = @"";
    }
    
    return data;
}

+ (id)sessionError
{
    NZNetData *data = [self netdataWithObject:nil];
    data.code = NZNetSessionErrCode;
    data.msg = NZNetSessionErrMsg;
    return data;
}

- (id)getRawData
{
    return _rawData;
}

#pragma mark - model transform
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic {
    NSMutableDictionary *transDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    if (!transDic[@"msg"]) {
        transDic[@"msg"] = dic[@"message"];
    }
    if (!transDic[@"rawData"]) {
        transDic[@"rawData"] = dic;
    }
    return transDic;
}

#pragma mark - NZNetworkEnvelopProtocol
- (id)getData {
    return _data;
}

- (id)getBizData {
    return _bizModel;
}

- (void)setBizData:(id)model {
    _bizModel = model;
}

@end
