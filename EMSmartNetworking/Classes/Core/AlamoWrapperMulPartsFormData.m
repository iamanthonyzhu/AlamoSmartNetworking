//
//  AlamoWrapperMulPartsFormData.m
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/3/29.
//

#import "AlamoWrapperMulPartsFormData.h"
#import "NFZMSmartNetworking_iOS-Swift.h"

typedef NS_ENUM(NSInteger, AWMulPartsFormDataType) {
    FileUrl_Name,
    FileUrl_Name_FileName_MimeType,
    ISData_Name_FileName_Length_MimeType,
    ISUrl_Name_FileName_Length_MimeType,
    FileData_Name_FileName_MimeType,
    FormData_Name,
    Headers_BodyData,
};

#define AWMulPartsFormDataConstructDomain @"com.alamofirewrapper.multipart"
#define AWMulPartsFormDataConstructError -2010

@interface AWQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end


NSArray * AWQueryStringPairsFromKeyAndValue(NSString *key, id value);
NSArray * AWQueryStringPairsFromDictionary(NSDictionary *dictionary);

NSArray * AWQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AWQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AWQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AWQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:AWQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:AWQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[AWQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

NSString * AWPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAWCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAWCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAWCharactersGeneralDelimitersToEncode stringByAppendingString:kAWCharactersSubDelimitersToEncode]];

    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }

    return escaped;
}

@implementation AWQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AWPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AWPercentEscapedStringFromString([self.field description]), AWPercentEscapedStringFromString([self.value description])];
    }
}

@end


@interface AWMultiPartData : NSObject
@property (nonatomic, assign) AWMulPartsFormDataType type;
@property (nonatomic, strong) NSURL *fileUrl;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) UInt64 length;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, strong) NSData *inputStramData;
@property (nonatomic, strong) NSURL *inputStramUrl;
@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSData *formData;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSData *bodyData;
@end

@implementation AWMultiPartData

@end

@interface AlamoWrapperMulPartsFormData()

@property (nonatomic, strong)NSMutableArray *parts;

@end

@implementation AlamoWrapperMulPartsFormData

- (NSMutableArray *)parts {
    if (!_parts) {
        _parts = [[NSMutableArray alloc] init];
    }
    return _parts;
}

- (void)appendParameters:(NSDictionary *)parameters {
    if (parameters) {
        for (AWQueryStringPair *pair in AWQueryStringPairsFromDictionary(parameters)) {
            NSData *data = nil;
            if ([pair.value isKindOfClass:[NSData class]]) {
                data = pair.value;
            } else if ([pair.value isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[pair.value description] dataUsingEncoding:NSUTF8StringEncoding];
            }
            
            if (data) {
                [self appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * _Nullable __autoreleasing *)error {
    if (!fileURL) {
        AWMultiPartData *part = [[AWMultiPartData alloc] init];
        part.type = FileUrl_Name;
        part.fileUrl = fileURL;
        part.name = name;
        [self.parts addObject:part];
        error = nil;
        return YES;
    }
    *error = [NSError errorWithDomain:AWMulPartsFormDataConstructDomain code:AWMulPartsFormDataConstructError userInfo:nil];
    return NO;
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *)error {
    if (!fileURL) {
        AWMultiPartData *part = [[AWMultiPartData alloc] init];
        part.type = FileUrl_Name_FileName_MimeType;
        part.fileUrl = fileURL;
        part.name = name;
        part.fileName = fileName;
        part.mimeType = mimeType;
        [self.parts addObject:part];
        return YES;
    }
    *error = [NSError errorWithDomain:AWMulPartsFormDataConstructDomain code:AWMulPartsFormDataConstructError userInfo:nil] ;
    return NO;

}
- (void)appendPartWithInputStreamData:(NSData *)isData
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                             mimeType:(NSString *)mimeType {
    AWMultiPartData *part = [[AWMultiPartData alloc] init];
    part.type = ISData_Name_FileName_Length_MimeType;
    part.inputStramData = isData;
    part.name = name;
    part.fileName = fileName;
    part.mimeType = mimeType;
    [self.parts addObject:part];
}

- (void)appendPartWithInputStreamUrl:(NSURL *)isUrl
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                            mimeType:(NSString *)mimeType {
    AWMultiPartData *part = [[AWMultiPartData alloc] init];
    part.type = ISUrl_Name_FileName_Length_MimeType;
    part.inputStramUrl = isUrl;
    part.name = name;
    part.fileName = fileName;
    part.mimeType = mimeType;
    [self.parts addObject:part];
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType {
    AWMultiPartData *part = [[AWMultiPartData alloc] init];
    part.type = FileData_Name_FileName_MimeType;
    part.fileData = data;
    part.name = name;
    part.fileName = fileName;
    part.mimeType = mimeType;
    [self.parts addObject:part];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name {
    AWMultiPartData *part = [[AWMultiPartData alloc] init];
    part.type = FormData_Name;
    part.formData = data;
    part.name = name;
    [self.parts addObject:part];
}

- (void)appendPartWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers
                         body:(NSData *)body {
    AWMultiPartData *part = [[AWMultiPartData alloc] init];
    part.type = Headers_BodyData;
    part.headers = headers;
    part.bodyData = body;
    [self.parts addObject:part];
}

/**
 Throttles request bandwidth by limiting the packet size and adding a delay for each chunk read from the upload stream.

 When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, there is no definite way to distinguish between a 3G, EDGE, or LTE connection over `NSURLConnection`. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.

 @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 16kb.
 @param delay Duration of delay each time a packet is read. By default, no delay is set.
 */
//- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
//                                  delay:(NSTimeInterval)delay;

- (void)convertToMulParsDataWrapper:(id)wrapper {
    if ([wrapper isKindOfClass:[MultipartDataWrapper class]]) {
        MultipartDataWrapper *dataWrapper = (MultipartDataWrapper *)wrapper;
        [self.parts enumerateObjectsUsingBlock:^(AWMultiPartData * _Nonnull part, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL result = NO;
            switch (part.type) {
                case FileUrl_Name:
                    result = [dataWrapper appendPartWithFileURL:part.fileUrl name:part.name];
                    break;
                case FileUrl_Name_FileName_MimeType:
                    result =[dataWrapper appendPartWithFileURL:part.fileUrl name:part.name fileName:part.fileName mimeType:part.mimeType];
                    break;
                case ISData_Name_FileName_Length_MimeType:
                    [dataWrapper appendPartWithInputStreamdata:part.inputStramData name:part.name fileName:part.fileName length:part.length mimeType:part.mimeType];
                    break;
                case ISUrl_Name_FileName_Length_MimeType:
                    result = [dataWrapper appendPartWithInputStreamUrl:part.inputStramUrl name:part.name fileName:part.fileName length:part.length mimeType:part.mimeType];
                    break;
                case FileData_Name_FileName_MimeType:
                    [dataWrapper appendPartWithFileData:part.fileData name:part.name fileName:part.fileName mimeType:part.mimeType];
                    break;
                case FormData_Name:
                    [dataWrapper appendPartWithFormData:part.formData name:part.name];
                    break;
                case Headers_BodyData:
                    [dataWrapper appendPartWithHeaders:part.headers body:part.bodyData];
                    break;
            }
        }];
    }
}
@end
