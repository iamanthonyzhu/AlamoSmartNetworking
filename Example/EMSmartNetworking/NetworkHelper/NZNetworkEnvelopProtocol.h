//
//  NZNetworkEnvelopProtocol.h
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//

#ifndef NZNetworkEnvelopProtocol_h
#define NZNetworkEnvelopProtocol_h

@protocol NZNetworkEnvelopProtocol <NSObject>

- (id)getData;

- (id)getBizData;

- (void)setBizData:(id)model;

@end

#endif /* NZNetworkEnvelopProtocol_h */
