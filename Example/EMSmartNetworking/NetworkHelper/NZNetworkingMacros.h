//
//  NZNetworkingMacros.h
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//

#ifndef NZNetworkingMacros_h
#define NZNetworkingMacros_h

#import "EMSmartNetworking_Example-Swift.h"
#import <AlamoSmartNetworking/AWMultipartsFormDataProtocol.h>

static NSString * const kNFZMNetModule = @"NFZMNetworkingModule";

#define force_inline __inline__ __attribute__((always_inline))

//#define EMLogInfo(module, format, ...) NSLog((format),##__VA_ARGS__)

/**
 请求成功回调

 @param task 请求task
 @param responseObject 请求响应内容
 */
typedef void(^NZAlamoSmartNetworkingSuccess)(NSURLSessionTask *task, id responseObject);

/**
 请求失败回调

 @param task 请求task
 @param error 错误
 @param responseObject 请求响应内容
 */
typedef void(^NZAlamoSmartNetworkingFailure)(NSURLSessionTask *task, NSError *error, id responseObject);

/**
 请求URL拼接的回调

 @param URLString 请求URL字符串
 @param APIName 接口名称
 @return 完整的接口请求URL字符串
 */
typedef NSString *(^NZAlamoSmartURLStringConstructor)(NSString *URLString, NSString *APIName);

/**
 请求参数的序列化回调

 @param parameters 请求参数
 @return 参数[字典格式]
 */
typedef NSDictionary *(^NZAlamoSmartParameterSerializer)(NSDictionary *paramters);

/**
 默认参数的配置

 @param baseURLString 请求的域名
 @param APIName 接口名称
 @param dicParams 请求所有参数
 @return 默认参数的字典
 */

typedef NSDictionary *(^NZAlamoSmartDefaultParamGetter)(NSString *baseURLString, NSString *apiName, NSDictionary *dicParams);


/**
 OAuth加签算法回调

 @param dicParams 请求所有参数
 @param APIName 接口名称
 @param signature 返回的加签得字段值
 @return OAuth加签后的请求参数
 */
typedef NSDictionary *(^NZAlamoSmartOAuthConfigurator)(NSDictionary *dicParams, NSString *APIName, NSString **signature);

/**
 NSMutableURLRequest header中添加的自定义参数

 @param baseURLString 请求的域名
 @param APIName 接口名称
 @param dicParams 请求所有参数
 @return 自定义参数字典
 */
typedef NSDictionary *(^NZAlamoSmartRequestHeaderGetter)(NSString *baseURLString, NSString *APIName, NSDictionary *dicParams);

/**
 请求response解析回调

 @param envelopeClass 外层结构【信封】的类别
 @param modelClass 接口对应的【信封】层的resultData的数据模型类别
 @param dataClass 接口对于resultData里层的data的数据模型类别
 @param JSONObject 请求返回的原始信息
 @param error 错误
 @return 解析后的response model
 */
typedef id(^NZAlamoSmartEnvelopeDeserializer)(__unsafe_unretained Class envelopeClass, __unsafe_unretained Class modelClass, __unsafe_unretained Class dataClass, id JSONObject);

/**
 重试机制回调

 @param stub 请求任务的存根
 @param response 请求响应
 @param responseObject 响应内容
 @param error 错误
 @return 是或否-->是否重试
 */
typedef BOOL(^NZAlamoSmartRetryConditioner)(NSURLSessionTask *task, NSURLResponse *response, id responseObject, NSError *error);

/**
 请求回调的拦截回调

 @param stub 请求存根
 @param response 请求响应
 @param responseObject 响应内容
 @param error 错误
 @param success 请求的成功回调
 @param failure 请求的失败回调
 */
typedef void(^NZAlamoSmartCompletionIntercepter)(NSURLSessionTask *stub, NSURLResponse *response, id responseObject, NSError *error, NZAlamoSmartNetworkingSuccess success, NZAlamoSmartNetworkingFailure failure);

/**
 是否需要SSL证书校验

 @param baseURLString  基础域名
 @return 是否需要校验
 */
typedef BOOL(^NZAlamoSmartNeedSSLCertificateVerification)(NSString *baseURLString);

/**
 SSL配置
 
 @return 保存了所有证书数据的一个数组
 */
typedef NSArray *(^NZAlamoSmartSSLConfigurator)(void);

/**
 证书校验
 
 @param session urlsession
 @param challenge 证书校验配置相关
 @param credential 证书
 @return 校验方式枚举值
 */
typedef NZURLAuthChallengeDisposition (^NZAlamoSmartAuthenticationChallenger)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *credential);


/**
 log输出
 */
typedef void(^NZNetworkLogInfo)(NSString *log);

#endif /* NZNetworkingMacros_h */
