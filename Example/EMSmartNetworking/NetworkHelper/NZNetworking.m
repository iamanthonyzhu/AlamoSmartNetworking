
//  EatNetWorking.m
//  BaseApp
//
//  Created by Infzm on 15/3/27.
//  Copyright (c) 2015年 sunima. All rights reserved.
//

#import "NZNetworking.h"
#import "NZNetworkingConfiguration.h"
#import <AlamoSmartNetworking/AWMultipartsFormDataProtocol.h>


NSString * const kNZReachabilityChangedNotification = @"kNZReachabilityChangedNotification";

@interface NZNetworking ()

@property(nonatomic, strong) NSMutableDictionary *errorHandlerBlocks;
@property(nonatomic, strong) NSMutableDictionary *downloadProgressDic;
@property(nonatomic, strong) NSMutableDictionary *downloadingBlockDic;
@property(nonatomic, strong) NSMutableDictionary *downloadTimerDic;


@property(nonatomic, strong) NSLock *lock;

@end


@implementation NZNetworking

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithParams{
    self = [super init];
    if (self) {
        
        self.errorHandlerBlocks = [NSMutableDictionary dictionary];
        self.lock = [[NSLock alloc] init];
        self.lock.name = @"nzNetWorkingLock";
    
        _netStatus = AlamoSmartNetStatusUnknown;
        [[NZAlamoSmartNetAgent shared] startReachabilityMonitoringWithListener:^(enum AlamoSmartNetStatus netStatus) {
            self.netStatus = netStatus;
            [[NSNotificationCenter defaultCenter] postNotificationName:kNZReachabilityChangedNotification object:@(netStatus)];
        }];
    
    }
    return self;
}

+ (NZNetworking *) shared
{
    static NZNetworking *client;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        client = [[NZNetworking alloc] initWithParams];
    });
    return client;
}

#pragma mark - 配置
- (void)setHeader:(NSString *)value forKey:(NSString *)key
{
    [[NZNetworkingConfiguration sharedInstance] setHeader:value forKey:key];
}

- (void)removeHeaderForKey:(NSString *)key
{
    [[NZNetworkingConfiguration sharedInstance] removeHeaderForKey:key];
}

#pragma mark - 网络监听
- (void)setNetStatus:(AlamoSmartNetStatus)netStatus
{
    _netStatus = netStatus;
    //NSLog(@"current status is %@", @(netStatus));
}

+ (NSString *)netStatusDescription:(AlamoSmartNetStatus)netStatus {
    NSString *str = @"Unknown";
    switch (netStatus) {
        case AlamoSmartNetStatusUnknown:
            str = @"Unknown";
            break;
        case AlamoSmartNetStatusNotReachable:
            str = @"Not Reachable";
            break;
        case AlamoSmartNetStatusConnectViaCellular:
            str = @"Cellular";
            break;
        case AlamoSmartNetStatusConnectViaEthOrWifi:
            str = @"EthOrWifi";
            break;
    }
    return str;
}

#pragma mark - 公共调用接口

- (BOOL)networkReachable {
    if (_netStatus == AlamoSmartNetStatusNotReachable || _netStatus == AlamoSmartNetStatusUnknown) {
        return NO;
    }
    return YES;
}

- (AlamoSmartNetStub *)get:(NSString *)url callback:(NZNetWorkingBlock)block
{
    return [self get:url parameters:nil timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)get:(NSString *)url timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    return [self get:url parameters:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)get:(NSString *)url parameters:(NSDictionary *)params callback:(NZNetWorkingBlock)block {
    return [self get:url parameters:params timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)get:(NSString *)url parameters:(NSDictionary *)params timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block {
    return [self get:url parameters:params modelCls:nil timeout:interval callback:block];
}
- (AlamoSmartNetStub *)get:(NSString *)url parameters:(NSDictionary *)params modelCls:(Class)modelCls timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
    } else {
        return [[NZAlamoSmartNetAgent shared] GET:url parameters:params.allKeys.count>0?params:nil success:^(NSURLSessionTask *task, id  responseObject) {
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NZNetData *netData = [NZNetData errorData:error];
            [self handlerErrorWithNetData:netData url:url parameters:params method:@"get" timeout:interval callback:block];
        } envelopeCls:[NZNetData class] modelCls:modelCls?modelCls:nil dataClas:nil timeout:@(interval)];
    }
    return nil;
}

- (AlamoSmartNetStub *)put:(NSString *)url callback:(NZNetWorkingBlock)block
{
    return [self put:url parameters:nil timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)put:(NSString *)url timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    return [self put:url parameters:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)put:(NSString *)url parameters:(NSDictionary *)params callback:(NZNetWorkingBlock)block {
    return [self put:url parameters:params timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)put:(NSString *)url parameters:(NSDictionary *)params timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block {
    return [self put:url parameters:params modelCls:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)put:(NSString *)url parameters:(NSDictionary *)params modelCls:(Class)modelCls timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block {
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
    } else {
        return [[NZAlamoSmartNetAgent shared] PUT:url parameters:params.allKeys.count>0?params:nil success:^(NSURLSessionTask *task, id  responseObject) {
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NZNetData *netData = [NZNetData errorData:error];
            [self handlerErrorWithNetData:netData url:url parameters:params method:@"put" timeout:interval callback:block];
        } envelopeCls:[NZNetData class] modelCls:modelCls?modelCls:nil dataClas:nil timeout:@(interval)];
    }
    return nil;

}


- (AlamoSmartNetStub *)post:(NSString *)url callback:(NZNetWorkingBlock)block
{
    return [self post:url parameters:nil timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)post:(NSString *)url timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    return [self post:url parameters:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)post:(NSString *)url parameters:(NSDictionary *)params callback:(NZNetWorkingBlock)block {
    return [self post:url parameters:params timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)post:(NSString *)url parameters:(NSDictionary *)params timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block {
    return [self post:url parameters:params modelCls:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)post:(NSString *)url parameters:(NSDictionary *)params modelCls:(Class)modelCls timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block) block([NZNetData badNetData]);
        });
    } else {
        return [[NZAlamoSmartNetAgent shared] POST:url parameters:params.allKeys.count>0?params:nil success:^(NSURLSessionTask *task, id  responseObject) {
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NZNetData *netData = [NZNetData errorData:error];
            [self handlerErrorWithNetData:netData url:url parameters:params method:@"post" timeout:interval callback:block];
        } envelopeCls:[NZNetData class] modelCls:modelCls?modelCls:nil dataClas:nil timeout:@(interval)];
    }
    return nil;
}

- (AlamoSmartNetStub *)postImage:(NSString *)url parameters:(NSDictionary *)params data:(NSData *)data dataKey:(NSString *)dataKey callback:(NZNetWorkingBlock)block
{
    //NSInputStream *input = [[NSInputStream alloc] initWithData:data];
    return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:params.allKeys.count>0?params:nil method:@"POST" constructingBodyWithBlock:^(id<AWMultipartsFormData> _Nonnull formData) {
        [formData appendPartWithInputStreamData:data name:dataKey fileName:[NSString stringWithFormat:@"%@.jpg", dataKey] length:data.length mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull progress) {
        //do nothing
    } success:^(NSURLSessionTask *task, id responseObject) {
        if (block) {
            block(responseObject);
        }
    } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
        NZNetData *netData = [NZNetData errorData:error];
        [self handlerErrorWithNetData:netData url:url parameters:params method:@"post" timeout:nzTime_out callback:block];
    } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
}

- (AlamoSmartNetStub *)delete:(NSString *)url callback:(NZNetWorkingBlock)block
{
    return [self delete:url parameters:nil timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)delete:(NSString *)url timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    return [self delete:url parameters:nil timeout:interval callback:block];
}

- (AlamoSmartNetStub *)delete:(NSString *)url parameters:(NSDictionary *)params callback:(NZNetWorkingBlock)block {
    return [self delete:url parameters:params timeout:nzTime_out callback:block];
}

- (AlamoSmartNetStub *)delete:(NSString *)url parameters:(NSDictionary *)params timeout:(CGFloat)interval callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
    } else {
        return [[NZAlamoSmartNetAgent shared] DELETE:url parameters:params.allKeys.count>0?params:nil success:^(NSURLSessionTask *task, id responseObject) {
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NZNetData *netData = [NZNetData errorData:error];
            [self handlerErrorWithNetData:netData url:url parameters:params method:@"delete" timeout:interval  callback:block];
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(interval)];
    }
    return nil;
}


- (AlamoSmartNetStub *)head:(NSString *)url
{
    return [self head:url parameters:nil];
}

- (AlamoSmartNetStub *)head:(NSString *)url parameters:(NSDictionary *)params
{
    return [[NZAlamoSmartNetAgent shared] HEAD:url parameters:params.allKeys.count>0?params:nil success:^(NSURLSessionTask * _Nullable task, id _Nullable responseObject) {
        //do nothing
    } failure:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error , id _Nullable responseObject) {
        // do nothing
    } envelopeCls:nil modelCls:nil dataClas:nil timeout:@(nzTime_out)];
}



#pragma mark - 错误处理
- (void)setErrorHandleBlock:(NZErrorHandleBlock)errorHandleBlock forErrorCode:(NSString *)errorCode
{
    if (errorHandleBlock) {
        [self.lock lock];
        [self.errorHandlerBlocks setObject:errorHandleBlock forKey:errorCode];
        [self.lock unlock];
    }
}

- (void)removeErrorHandlerBlockForErrorCode:(NSString *)errorCode
{
    [self.lock lock];
    [self.errorHandlerBlocks removeObjectForKey:errorCode];
    [self.lock unlock];
}

#pragma mark - 下载文件
- (AlamoSmartNetStub *)download:(NSString *)url downloading:(void(^)(CGFloat progress))downloadingBlock finishedBlock:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        __block NSURL *destPath = nil;
        return [[NZAlamoSmartNetAgent shared] DOWNLOAD:url destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            destPath = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
            return destPath;
        } progress:^(NSProgress *progress) {
            if (downloadingBlock) {
                CGFloat total = progress.totalUnitCount + 0.0;
                CGFloat completed = progress.completedUnitCount + 0.0;
                if (total == 0) {
                    return;
                }
                CGFloat p = completed / total;
                if (p < 0) {
                   NSLog(@"进度异常（总：%f，完成：%f）：%f", total, completed, p);
                   return;
                }
                if (p < 1) {
                    if (![[NSThread currentThread] isMainThread]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            downloadingBlock(p);
                        });
                    } else {
                        downloadingBlock(p);
                    }
                }
            }
        } success:^(NSURLSessionTask *task, id responseObject) {
            if (downloadingBlock) {
                downloadingBlock(1);
            }
            if (block) {
                block([NZNetData netdataWithObject:destPath]);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:nil modelCls:nil dataClas:nil timeout:@(nzDownloadTime_out)];
    }

}

- (AlamoSmartNetStub *)download:(NSString *)url downloading:(void(^)(CGFloat progress))downloadingBlock destination:(NZNetworkingDestination)destBlock finishedBlock:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        __block NSURL *destPath = nil;
        return [[NZAlamoSmartNetAgent shared] DOWNLOAD:url destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            if (destBlock) {
                return destBlock(targetPath,response);
            }
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            destPath = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
            return destPath;
        } progress:^(NSProgress *progress) {
            if (downloadingBlock) {
                CGFloat total = progress.totalUnitCount + 0.0;
                CGFloat completed = progress.completedUnitCount + 0.0;
                if (total == 0) {
                    return;
                }
                CGFloat p = completed / total;
                if (p < 0) {
                   //DLog(@"进度异常（总：%f，完成：%f）：%f", total, completed, p);
                   return;
                }
                if (p < 1) {
                    if (![[NSThread currentThread] isMainThread]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            downloadingBlock(p);
                        });
                    } else {
                        downloadingBlock(p);
                    }
                }
            }
        } success:^(NSURLSessionTask *task, id responseObject) {
            if (downloadingBlock) {
                downloadingBlock(1);
            }
            if (block) {
                block([NZNetData netdataWithObject:destPath]);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:nil modelCls:nil dataClas:nil timeout:@(nzDownloadTime_out)];
    }
}

#pragma mark - 上传文件
- (AlamoSmartNetStub *)upload:(NSString *)url withFilePath:(NSString *)filePath parameters:(NSDictionary *)parameters callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        NSURL *file = [NSURL fileURLWithPath:filePath];
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileURL:file name:@"file" error:nil];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

- (AlamoSmartNetStub *)upload:(NSString *)url filePath:(NSURL *)fileURL parameters:(NSDictionary *)parameters callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        if (!url ||!fileURL) {
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([NZNetData badNetData]);
                });
            }
            return nil;
        }
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:data name:@"log" fileName:@"file.zip" mimeType:@"application/zip"];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

- (AlamoSmartNetStub *)upload:(NSString *)url withImage:(UIImage *)image parameters:(NSDictionary *)parameters callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:data name:@"headimage" fileName:@"image" mimeType:@"image/jpeg"];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

- (AlamoSmartNetStub *)upload:(NSString *)url
      withImage:(UIImage *)image
      imageName:(NSString *)imageName
       mimeType:(NSString *)mimeType
     parameters:(NSDictionary *)parameters
      modelCls:(Class)modelCls
       callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:data name:@"file" fileName:imageName ? : @"" mimeType:mimeType];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:modelCls dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

- (AlamoSmartNetStub *)uploadVideoWithURL:(NSString *)url
                  videoURL:(NSURL *)videoURL
                 videoName:(NSString *)videoName
                  mimeType:(NSString *)mimeType
                parameters:(NSDictionary *)parameters
                  callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        NSData *data = [NSData dataWithContentsOfURL:videoURL];
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:data name:@"file" fileName:videoName mimeType:mimeType];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

- (AlamoSmartNetStub *)uploadFileWithURL:(NSString *)url
                  fileURL:(NSURL *)fileURL
               parameters:(NSDictionary *)parameters
                 callback:(NZNetWorkingBlock)block
{
    if (self.netStatus == AlamoSmartNetStatusNotReachable) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([NZNetData badNetData]);
            });
        }
        return nil;
    } else {
        NSString *fileName = [fileURL lastPathComponent];
        NSString *mimeType = [self contentTypeForPathExtension:[fileURL pathExtension]];
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if (!data) {
            if (block) {
                block([NZNetData badNetData]);
            }
            return nil;
        }
        
        return [[NZAlamoSmartNetAgent shared] UPLOAD:url parameters:parameters.allKeys.count>0?parameters:nil method:@"POST"  constructingBodyWithBlock:^(id<AWMultipartsFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:data name:@"file" fileName:fileName mimeType:mimeType];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"Success: %@", responseObject);
            //NZNetData *data = [NZNetData netdataWithObject:responseObject];
            if (block) {
                block(responseObject);
            }
        } failure:^(NSURLSessionTask *task, NSError *error, id responseObject) {
            NSLog(@"Error: %@", error);
            if (block) {
                block([NZNetData errorData:error]);
            }
        } envelopeCls:[NZNetData class] modelCls:nil dataClas:nil timeout:@(nzUploadTime_out)];
    }
}

#pragma mark - error handler
- (void)handlerErrorWithNetData:(NZNetData *)netData url:(NSString *)url parameters:(NSDictionary *)parameters method:(NSString *)method timeout:(CGFloat)interval callback:(NZNetWorkingBlock)callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *errorCode = [NSString stringWithFormat:@"%ld", netData.code];
        NZErrorHandleBlock block = [self.errorHandlerBlocks objectForKey:errorCode];
        BOOL shouldReRequest = NO;
        if (block) {
            shouldReRequest = block(netData);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (shouldReRequest)
            {
                if ([method isEqualToString:@"get"])
                {
                    [self get:url parameters:parameters timeout:interval callback:callback];
                }
                else if ([method isEqualToString:@"post"])
                {
                    [self post:url parameters:parameters timeout:interval callback:callback];
                }
                else if ([method isEqualToString:@"put"])
                {
                    [self put:url parameters:parameters timeout:interval callback:callback];
                }
                else if ([method isEqualToString:@"delete"])
                {
                    [self delete:url parameters:parameters timeout:interval callback:callback];
                }
            }
            else
            {
                if (callback) {
                    callback(netData);
                }
            }
        });
        
    });
}

- (NSString *)contentTypeForPathExtension:(NSString *)extension {
#ifdef __UTTYPE__
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
#else
#pragma unused (extension)
    return @"application/octet-stream";
#endif
}

@end
