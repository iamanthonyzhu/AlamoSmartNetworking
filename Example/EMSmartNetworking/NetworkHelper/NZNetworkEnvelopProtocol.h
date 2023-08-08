//
//  NZNetworkEnvelopProtocol.h
//  nfzm
//
//  Created by anthony zhu on 2021/12/24.
//  Copyright © 2021 nfzm. All rights reserved.
//

#ifndef NZNetworkEnvelopProtocol_h
#define NZNetworkEnvelopProtocol_h

@protocol NZNetworkEnvelopProtocol <NSObject>

- (id)getData;

- (id)getBizData;

- (void)setBizData:(id)model;

@end

#endif /* NZNetworkEnvelopProtocol_h */
