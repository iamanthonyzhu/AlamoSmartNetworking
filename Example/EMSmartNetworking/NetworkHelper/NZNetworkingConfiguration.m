//
//  NZNetworkingConfiguration.m
//  nfzm
//
//  Created by anthony zhu on 2021/12/23.
//  Copyright © 2021 nfzm. All rights reserved.
//

#import "NZNetworkingConfiguration.h"
#import <YYModel/NSObject+YYModel.h>
#import "NZNetworkEnvelopProtocol.h"
#import "NZAlamoSmartResponseDeserializer.h"
#import "NZNetworkingMacros.h"
#import <extobjc/EXTScope.h>



#define CERT_Expiry_Date @"2024/02/07 00:00:00"

static NSString *const kContentType = @"Content-Type";
static NSString *const kAccept = @"Accept";
static NSString *const kTokenKey = @"PET-SESSION-TOKEN";
static NSString *const kSignKey = @"X-XCLOUD-SIGN";
static NSString *const kUserId = @"User-Id";
static NSString *const kUserAgent = @"User-Agent";
static NSString *const kPlatform = @"platform";

static NSString * const kErrorDomain = @"nz.Networking";

static force_inline id NZNetworkingJSonObjectByRemovingKeysWithNullValue(id JSonObject) {
    if ([JSonObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
        NSDictionary *dictJSon = (NSDictionary *)JSonObject;
        NSArray *allKeys = dictJSon.allKeys;
        for (id key in allKeys) {
            @autoreleasepool {
                id value = dictJSon[key];
                if (!value
                    || ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"null"])
                    || [value isEqual:[NSNull null]]) {
                    continue;
                }
                [tempDict setObject:NZNetworkingJSonObjectByRemovingKeysWithNullValue(dictJSon[key]) forKey:key];
            }
        }
        return [tempDict copy];
    } else if ([JSonObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *tempArray = [NSMutableArray array];
        NSArray *arrayJSon = (NSArray *)JSonObject;
        for (id element in arrayJSon) {
            @autoreleasepool {
                [tempArray addObject:NZNetworkingJSonObjectByRemovingKeysWithNullValue(element)];
            }
        }
        return [tempArray copy];
    } else {
        return JSonObject;
    }
}


@interface NZNetworkingConfiguration()

@property (nonatomic,strong) NSMutableDictionary *defaultHeaders;

@property (nonatomic, copy) NZAlamoSmartURLStringConstructor URLStringConfigurator;
@property (nonatomic, copy) NZAlamoSmartParameterSerializer parametersSerializer;
@property (nonatomic, copy) NZAlamoSmartDefaultParamGetter defaultParameterGetter;
@property (nonatomic, copy) NZAlamoSmartOAuthConfigurator OAuthConfigurator;
@property (nonatomic, copy) NZAlamoSmartRequestHeaderGetter requestHeaderGetter;
@property (nonatomic, copy) NZAlamoSmartEnvelopeDeserializer envelopeDeserializer;
@property (nonatomic, copy) NZAlamoSmartRetryConditioner retryConditioner;
@property (nonatomic, copy) NZAlamoSmartCompletionIntercepter completionIntercepter;
@property (nonatomic, copy) NZAlamoSmartNeedSSLCertificateVerification needCertificateVerification;
@property (nonatomic, copy) NZAlamoSmartSSLConfigurator SSLConfigurator;
@property (nonatomic, copy) NZAlamoSmartAuthenticationChallenger authenticationChanllenger;
@property (nonatomic, copy) NZNetworkLogInfo logInfo;


@end

@implementation NZNetworkingConfiguration

+ (instancetype)sharedInstance
{
    static NZNetworkingConfiguration *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NZNetworkingConfiguration alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self.defaultHeaders setValue:@"application/json" forKey:kAccept];
    
    self.defaultParameterGetter = ^NSDictionary *(NSString *baseURLString, NSString *APIName, NSDictionary *dicParams) {
        return @{};
    };
    
    @weakify(self)
    self.requestHeaderGetter = ^NSDictionary *(NSString *baseURLString, NSString *APIName, NSDictionary *dicParams) {
        @strongify(self)
        return self.defaultHeaders;
    };
    
//    self.parametersSerializer = ^NSDictionary *(id parameters, NSError **error) {
//        NSDictionary *dicParams;
//        if ([parameters isKindOfClass:[NSDictionary class]]) {
//            dicParams = (NSDictionary *)parameters;
//        } else if ([parameters respondsToSelector:@selector(modelToJSONObject)]) {
//            dicParams = [parameters modelToJSONObject];
//        }
//        return dicParams;
//    };
    
//    self.URLStringConfigurator = ^NSString *(NSString *URLString, NSString *APIName) {
//
//        return URLString;
//    };
    
    self.envelopeDeserializer = ^id(__unsafe_unretained Class envelopeClass, __unsafe_unretained Class modelClass, __unsafe_unretained Class dataCls, id JSONObject) {
        
        if ([JSONObject isKindOfClass:[NSData class]]) {
            id JsonData = NZAlamoSmartResponseJsonData(JSONObject);
            if (JsonData) {
                JSONObject = JsonData;
            } else { // 不是json格式的，直接解析成字符串返回
                JSONObject = [[NSString alloc] initWithData:JSONObject encoding:NSUTF8StringEncoding];
                //*error = nil;
                if (![JSONObject hasPrefix:@"{"]) {
                    return nil;
                }
            }
        }
        id<NZNetworkEnvelopProtocol> envObject = [NZNetworkingConfiguration deserializerResponse:JSONObject WithEnvelopeClass:envelopeClass];
        if (envObject && [envObject respondsToSelector:@selector(getData)] && modelClass) {
            id deserializerModel = [NZNetworkingConfiguration deserializerResponse:[envObject getData] withModelClass:modelClass];
            if (deserializerModel && [envObject respondsToSelector:@selector(setBizData:)]) {
                [envObject setBizData:deserializerModel];
            }
        }
        return envObject;
    };

    self.completionIntercepter = ^(NSURLSessionTask *task, NSURLResponse *response, id responseObject, NSError *error, NZAlamoSmartNetworkingSuccess success, NZAlamoSmartNetworkingFailure failure) {
        if (error) {
            NSError *networkLink = [NSError errorWithDomain:kErrorDomain code:error.code userInfo:nil];
            failure(task, networkLink, responseObject);
        } else {
            success(task, responseObject);
        }
    };
    
    self.logInfo = ^(NSString *log) {
        //EMLogInfo(kNFZMNetModule, log);
    };
    
#if VERIFY_OFF
        self.needCertificateVerification = ^BOOL(NSString *baseURLString) {
            return NO;
        };
#endif
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd hh:mm:ss"];
        NSDate *exDate = [dateFormatter dateFromString:CERT_Expiry_Date];
        if ([[NSDate date] timeIntervalSince1970] >= [exDate timeIntervalSince1970]) {
            self.needCertificateVerification = ^BOOL(NSString *baseURLString) {
                return NO;
            };
        } else {
            self.needCertificateVerification = ^BOOL(NSString *baseURLString) {
                if ([baseURLString hasPrefix:@"https://api.infzm.com"] || [baseURLString hasPrefix:@"https://passport.infzm.com"]) {
                    return YES;
                }
                return NO;
            };
        }
        
        self.SSLConfigurator = ^NSArray *{
            //使用mainbundle中默认.cer证书作为https校验
//            NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"new.infzm.com" ofType:@"cer"];//证书的路径
//            if (cerPath.length > 0) {
//                NSData *certData = [NSData dataWithContentsOfFile:cerPath];
//                return @[certData];
//            }
            return nil;
        };

    
    [[NZAlamoSmartNetConfig shared] setupWithUrlConstructor:self.URLStringConfigurator parameterSerializer:self.parametersSerializer defaultParamGetter:self.defaultParameterGetter oauthConfigurator:nil requestHeaderGetter:self.requestHeaderGetter envDeserializer:self.envelopeDeserializer retryConditioner:self.retryConditioner completeIntercepter:self.completionIntercepter sslCertVerify:self.needCertificateVerification sslConfiguartor:self.SSLConfigurator authChallengeDispos:self.authenticationChanllenger netLogInfo:self.logInfo];
}

#pragma mark - Class Function

+ (id<NZNetworkEnvelopProtocol>)deserializerResponse:(id)JSONObject WithEnvelopeClass:(Class)envelopeClass {
    id formatJSONObject = NZNetworkingJSonObjectByRemovingKeysWithNullValue(JSONObject);
    if ([envelopeClass respondsToSelector:@selector(netdataWithObject:)]) {
        return [envelopeClass performSelector:@selector(netdataWithObject:) withObject:JSONObject];
    }
    return formatJSONObject;
}

+ (id)deserializerResponse:(id<NZNetworkEnvelopProtocol>)bizData withModelClass:(Class)modelClass {
    id deserializerModel;
    if ([bizData isKindOfClass:[NSDictionary class]]) {
        if ([modelClass respondsToSelector:@selector(yy_modelWithJSON:)]) {
            deserializerModel = [modelClass yy_modelWithJSON:bizData];
        }
    } else if ([bizData isKindOfClass:[NSArray class]]) {
        deserializerModel = [NSArray yy_modelArrayWithClass:modelClass json:bizData];
    }
    return deserializerModel;
}


#pragma mark - getter setter
- (NSMutableDictionary *)defaultHeaders {
    if (!_defaultHeaders) {
        _defaultHeaders = [[NSMutableDictionary alloc] init];
    }
    return _defaultHeaders;
}

- (void)setHeader:(NSString *)value forKey:(NSString *)key
{
    [self.defaultHeaders setValue:value forKey:key];
}

- (void)removeHeaderForKey:(NSString *)key
{
    [self.defaultHeaders removeObjectForKey:key];
}


@end


