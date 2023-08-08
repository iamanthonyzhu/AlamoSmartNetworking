//
//  AlamoWrapperMulPartsFormData.h
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/3/29.
//

#import <Foundation/Foundation.h>
#import "AWMultipartsFormDataProtocol.h"

@interface AlamoWrapperMulPartsFormData : NSObject<AWMultipartsFormData>

- (void)appendParameters:(NSDictionary *)parameters;
- (void)convertToMulParsDataWrapper:(id)dataWrapper;
@end

