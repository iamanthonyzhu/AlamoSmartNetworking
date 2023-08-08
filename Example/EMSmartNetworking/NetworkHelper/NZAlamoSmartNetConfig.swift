//
//  NZAlamoSmartNetConfig.swift
//
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 . All rights reserved.
//

import Foundation
import AlamoSmartNetworking

@objc enum NZURLAuthChallengeDisposition : Int {
    case NZNSURLSessionAuthChallengeUseCredential = 0,
         NZNSURLSessionAuthChallengePerformDefaultHandling,
         NZNSURLSessionAuthChallengeCancelAuthenticationChallenge,
         NZNSURLSessionAuthChallengeRejectProtectionSpace
}

typealias NZURLStringConstructor = (NSString, NSString) -> NSString
typealias NZParameterSerializer = (NSDictionary) -> NSDictionary
typealias NZDefaultParamGetter = (NSString, NSString, NSMutableDictionary) -> NSDictionary
typealias NZOAuthConfigurator = (NSMutableDictionary, NSString, UnsafePointer<NSString>) -> NSDictionary
typealias NZRequestHeaderGetter = (NSString,NSString,NSMutableDictionary) -> NSDictionary
typealias NZEnvelopeDeserializer = (AnyClass?,AnyClass?,AnyClass?,AnyObject?) -> AnyObject
typealias NZRetryConditioner = (URLSessionTask?,URLResponse?,AnyObject?,NSError?) -> Bool
typealias NZCompletionIntercepter = (URLSessionTask?,URLResponse?,AnyObject?,NSError?,NZSmartAgentSuccessCallback,NZSmartAgentFailureCallback) -> Void
typealias NZNeedSSLCertificateVerification = (NSString) -> Bool
typealias NZSSLConfigurator = () -> NSArray
typealias NZAuthChallengeDisposition = (URLSession, URLAuthenticationChallenge, URLCredential) -> NZURLAuthChallengeDisposition
typealias NZNetLogInfo = (NSString) -> Void


@objc protocol NZSmartConfigurationProtocol {
}



@objc open class NZAlamoSmartNetConfig : NSObject,AlamoSmartConfigurationProtocol {
    
    @objc static let shared = NZAlamoSmartNetConfig()
    override private init() {}
    
    var urlConstructor:NZURLStringConstructor? = nil
    var parameterSerializer:NZParameterSerializer? = nil
    var defaultParamGetter:NZDefaultParamGetter? = nil
    var oauthConfigurator:NZOAuthConfigurator? = nil
    var requestHeaderGetter:NZRequestHeaderGetter? = nil
    var envDeserializer:NZEnvelopeDeserializer? = nil
    var retryConditioner:NZRetryConditioner? = nil
    var completeIntercepter:NZCompletionIntercepter? = nil
    var sslCertVerify:NZNeedSSLCertificateVerification? = nil
    var sslConfiguartor:NZSSLConfigurator? = nil
    var authChallengeDispos:NZAuthChallengeDisposition? = nil
    var netLogInfo:NZNetLogInfo? = nil

    
    @objc func setup(urlConstructor:NZURLStringConstructor? = nil,parameterSerializer:NZParameterSerializer? = nil,defaultParamGetter:NZDefaultParamGetter? = nil,oauthConfigurator:NZOAuthConfigurator? = nil,requestHeaderGetter:NZRequestHeaderGetter? = nil,envDeserializer:NZEnvelopeDeserializer? = nil,retryConditioner:NZRetryConditioner? = nil,completeIntercepter:NZCompletionIntercepter? = nil,sslCertVerify:NZNeedSSLCertificateVerification? = nil,sslConfiguartor:NZSSLConfigurator? = nil,authChallengeDispos:NZAuthChallengeDisposition? = nil,netLogInfo:NZNetLogInfo? = nil) {
        self.urlConstructor = urlConstructor
        self.parameterSerializer = parameterSerializer
        self.defaultParamGetter = defaultParamGetter
        self.oauthConfigurator = oauthConfigurator
        self.requestHeaderGetter = requestHeaderGetter
        self.envDeserializer = envDeserializer
        self.retryConditioner = retryConditioner
        self.completeIntercepter = completeIntercepter
        self.sslCertVerify = sslCertVerify
        self.sslConfiguartor = sslConfiguartor
        self.authChallengeDispos = authChallengeDispos
        self.netLogInfo = netLogInfo
    }
    
    public func alamoSmartURLStringConstructor(urlString: String, apiName: String) -> String {
        if let constructor = urlConstructor {
            return String(constructor(NSString(string: urlString),NSString(string: apiName)))
        }
        return urlString
    }
    
    public func alamoSmartParameterSerializer(parameters: AnyObject) -> [String : AnyObject]? {
        if let serializer = parameterSerializer, let params = parameters as? [String:AnyObject] {
            return serializer(NSDictionary(dictionary: params)) as? [String:AnyObject]
        }
        return parameters as? [String:AnyObject]
    }
    
    public func alamoSmartDefaultParameterGetter(baseURLString: String, apiName: String, dicParams: [String : AnyObject]) -> [String : AnyObject]? {
        if let getter = defaultParamGetter {
            return getter(NSString(string: baseURLString), NSString(string: apiName), NSMutableDictionary(dictionary: dicParams)) as? [String:AnyObject]
        }
        return dicParams
    }
    
    public func alamoSmartOAuthConfigurator(dicParams: [String : AnyObject], apiName: String, signature: inout String) -> [String : AnyObject] {
        if let configurator = oauthConfigurator {
            let sign = withUnsafePointer(to: NSString(string: signature)) { ptr in
                ptr
            }
            return (configurator(NSMutableDictionary(dictionary: dicParams), NSString(string: apiName), sign) as? [String:AnyObject]) ?? dicParams
        }
        return dicParams
    }
    
    public func alamoSmartRequestHeaderGetter(baseURLString: String, apiName: String, dicParams: [String : AnyObject]) -> [String : String]? {
        if let getter = requestHeaderGetter {
            return getter(NSString(string: baseURLString),NSString(string: apiName),NSMutableDictionary(dictionary: dicParams)) as? [String:String]
        }
        return nil

    }
    
    public func alamoSmartEnvelopeDeserializer(envelopeClass: AnyClass?, modelClass: AnyClass?, dataClass: AnyClass?, jsonObject: AnyObject?) -> AnyObject? {
        if let deserializer = envDeserializer {
            return deserializer(envelopeClass ?? nil ,modelClass ?? nil,dataClass ?? nil,jsonObject ?? nil)
        }
        return nil
    }
    
    public func alamoSmartRetryConditioner(task: URLSessionTask?, response: HTTPURLResponse?, responseObject:AnyObject?,error: Error?) -> Bool {
        if let retry = retryConditioner {
            return retry(task ?? nil , response ?? nil, responseObject ?? nil, error as? NSError ?? nil)
        }
        return false
    }
    
    public func alamoSmartCompletionIntercepter(task: URLSessionTask?, response: HTTPURLResponse?, responseObject: AnyObject?, error: Error?, success: (URLSessionTask?, AnyObject?) -> (), failure: (URLSessionTask?, Error?, AnyObject?) -> ()) {
        if let complete = completeIntercepter {
            complete(task ?? nil, response ?? nil, responseObject ?? nil, error as? NSError ?? nil, success, failure)
        }
    }
    
    public func alamoSmartNeedSSLCertificateVerification(baseURLString: String) -> Bool {
        if let certVerfiy = sslCertVerify {
            return certVerfiy(NSString(string: baseURLString))
        }
        return false
    }
    
    public func alamoSmartSSLConfigurator() -> [AnyObject]? {
        if let sslConfig = sslConfiguartor {
            return sslConfig() as [AnyObject]
        }
        return nil
    }
    
    public func alamoSmartAuthenticationChallenger(session: URLSession, challenge: URLAuthenticationChallenge, credential:URLCredential) -> URLSession.AuthChallengeDisposition {
        if let authChallenge = authChallengeDispos {
            let result = authChallenge(session,challenge,credential)
            switch result {
            case .NZNSURLSessionAuthChallengeUseCredential:
                return URLSession.AuthChallengeDisposition.useCredential
            case .NZNSURLSessionAuthChallengePerformDefaultHandling:
                return URLSession.AuthChallengeDisposition.performDefaultHandling
            case .NZNSURLSessionAuthChallengeCancelAuthenticationChallenge:
                return URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
            case .NZNSURLSessionAuthChallengeRejectProtectionSpace:
                return URLSession.AuthChallengeDisposition.rejectProtectionSpace
            }
        }
        return URLSession.AuthChallengeDisposition.performDefaultHandling
    }
    
    public func alamoSmartNetworkLogInfo(log:String) -> Void {
        //self.netLogInfo?(NSString(string: log))
        print(log)
    }
    
}

