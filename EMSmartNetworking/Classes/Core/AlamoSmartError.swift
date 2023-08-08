//
//  AlamoSmartError.swift
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/4/26.
//

import Foundation

public enum AlamoSmartError : Error {
    public enum UndefinedReason {
        case AlamoSmartNetErrorUnknown
        case AlamoSmartNetErrorNone
    }
    
    public enum RequestSerializerReason {
        case AlamoSmartErrorCreateRequestFailed
        case AlamoSmartErrorNotExistParamter
        case AlamoSmartErrorValidateParameter
        case AlamoSmartErrorNotExistURLParameter
    }
    
    public enum OAuthReason {
        case AlamoSmartErrorOAuthFailed
    }
    
    public enum ResponseDeserializerReason {
        case AlamoSmartErrorParseResponseObjectFailed
        case AlamoSmartErrorSealREsponseEnvelopeFailed
        case AlamoSmartErrorSeralREsponseModelFailed
    }
    
    case undefinedError(reason:UndefinedReason)
    case requestSerializerError(reason:RequestSerializerReason)
    case oauthError(reason:OAuthReason)
    case responseDeserializerError(reason:ResponseDeserializerReason)
}

