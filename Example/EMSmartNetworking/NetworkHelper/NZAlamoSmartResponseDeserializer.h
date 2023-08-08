//
//  NZAlamoSmartResponseDeserializer.h
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundefined-inline"
extern inline NSInteger NZAlamoSmartResponseStatusCode(NSURLResponse *response);

extern inline id NZAlamoSmartResponseJsonData(NSData *responseData);

extern inline Class NZAlamoSmartResponseModelClass(NSString *APIName, NSString *method);
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

@interface NZAlamoSmartResponseDeserializer : NSObject

@end

NS_ASSUME_NONNULL_END
