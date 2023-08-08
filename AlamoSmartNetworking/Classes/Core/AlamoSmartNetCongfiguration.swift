//
//  AlamoSmartNetCongfiguration.swift
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/4/25.
//

import Foundation
import Alamofire

public typealias AlamoSmartSuccessCallback = (URLSessionTask?, AnyObject?) -> ()
public typealias AlamoSmartFailureCallback = (URLSessionTask?, Error?, AnyObject?) -> ()
public typealias AlamoSmartTaskAsyncConstructor = (URLSessionTask?)->()
public typealias AlamoSmartRequestSyncConstructor = (Request?)->()
public typealias AlamoSmartCompleteHanlder = (HTTPURLResponse?,AnyObject?,Error?)->()
public typealias AlamoURLConstructor = (String,[String:AnyObject]?) -> String
public typealias AlamoSmartProgressCallback = (Float, Float) -> ()
public typealias AlamoSmartDestinationCallback = (URL,HTTPURLResponse) -> URL
public typealias AlamoSmartMultipartDataConstructor = (MultipartDataWrapper) -> ()
public typealias AlamoAgentMultipartDataConstructor = (AWMultipartsFormData) -> ()

public typealias AlamoSmartStubConstructor = (@escaping AlamoSmartRequestSyncConstructor, @escaping AlamoSmartTaskAsyncConstructor,@escaping AlamoSmartCompleteHanlder)->()

public protocol AlamoSmartConfigurationProtocol{
    /**
     请求URL拼接的回调

     @param URLString 请求URL字符串
     @param APIName 接口名称
     @return 完整的接口请求URL字符串
     */
    func alamoSmartURLStringConstructor(urlString:String, apiName:String) -> String

    /**
     请求参数的序列化回调

     @param parameters 请求参数
     @param error 错误
     @return 参数[字典格式]
     */
    func alamoSmartParameterSerializer(parameters:AnyObject) -> [String:AnyObject]?

    /**
     默认参数的配置

     @param baseURLString 请求的域名
     @param APIName 接口名称
     @param dicParams 请求所有参数
     @return 默认参数的字典
     */
    func alamoSmartDefaultParameterGetter(baseURLString:String, apiName:String, dicParams:[String:AnyObject]) -> [String:AnyObject]?

    /**
     OAuth加签算法回调

     @param dicParams 请求所有参数
     @param APIName 接口名称
     @param signature 返回的加签得字段值
     @return OAuth加签后的请求参数
     */
    func alamoSmartOAuthConfigurator(dicParams:[String:AnyObject], apiName:String, signature:inout String) -> [String:AnyObject]

    /**
     NSMutableURLRequest header中添加的自定义参数

     @param baseURLString 请求的域名
     @param APIName 接口名称
     @param dicParams 请求所有参数
     @return 自定义参数字典
     */
    func alamoSmartRequestHeaderGetter(baseURLString:String, apiName:String, dicParams:[String:AnyObject]) -> [String:String]?

    /**
     请求response解析回调

     @param envelopeClass 外层结构【信封】的类别
     @param modelClass 接口对应的【信封】层的resultData的数据模型类别
     @param dataClass 接口对于resultData里层的data的数据模型类别
     @param JSONObject 请求返回的原始信息
     @param error 错误
     @return 解析后的response model
     */
    func alamoSmartEnvelopeDeserializer(envelopeClass:AnyClass?, modelClass:AnyClass?, dataClass:AnyClass?, jsonObject:AnyObject?) -> AnyObject?

    /**
     重试机制回调

     @param stub 请求任务的存根
     @param response 请求响应
     @param responseObject 响应内容
     @param error 错误
     @return 是或否-->是否重试
     */
    func alamoSmartRetryConditioner(task:URLSessionTask?, response:HTTPURLResponse?, responseObject:AnyObject?, error:Error?) -> Bool

    /**
     请求回调的拦截回调

     @param stub 请求存根
     @param response 请求响应
     @param responseObject 响应内容
     @param error 错误
     @param success 请求的成功回调
     @param failure 请求的失败回调
     */
    func alamoSmartCompletionIntercepter(task:URLSessionTask?, response:HTTPURLResponse?, responseObject:AnyObject?, error:Error?, success:AlamoSmartSuccessCallback, failure:AlamoSmartFailureCallback)

    /**
     是否需要SSL证书校验

     @param baseURLString  基础域名
     @return 是否需要校验
     */
    func alamoSmartNeedSSLCertificateVerification(baseURLString:String) -> Bool

    /**
     SSL配置
     
     @return 保存了所有证书数据的一个数组
     */
    func alamoSmartSSLConfigurator() -> [AnyObject]?
    
    /**
     证书校验
     
     @param session urlsession
     @param challenge 证书校验配置相关
     @param credential 证书
     @return 校验方式枚举值
     */
    func alamoSmartAuthenticationChallenger(session:URLSession, challenge:URLAuthenticationChallenge, credential:URLCredential) -> URLSession.AuthChallengeDisposition

    func alamoSmartNetworkLogInfo(log:String) -> Void

}


open class AlamoSmartNetConfiguration : AlamoSmartConfigurationProtocol {
    
    static let shared = AlamoSmartNetConfiguration()
    private init() {}
    
    public func alamoSmartURLStringConstructor(urlString:String, apiName:String) -> String {
        return urlString
    }

    public func alamoSmartParameterSerializer(parameters: AnyObject) -> [String : AnyObject]? {
        if let param = parameters as? [String:AnyObject] {
            return param
        }
        return nil
    }

    public func alamoSmartDefaultParameterGetter(baseURLString:String, apiName:String, dicParams:[String:AnyObject]) -> [String:AnyObject]? {
        return nil
    }

    public func alamoSmartOAuthConfigurator(dicParams:[String:AnyObject], apiName:String, signature:inout String) -> [String:AnyObject] {
        return dicParams
    }

    public func alamoSmartEnvelopeDeserializer(envelopeClass: AnyClass?, modelClass: AnyClass?, dataClass: AnyClass?, jsonObject: AnyObject?) -> AnyObject? {
        return jsonObject
    }

    public func alamoSmartRetryConditioner(task: URLSessionTask?, response: HTTPURLResponse?, responseObject:AnyObject?, error: Error?) -> Bool {
        return false
    }
    
    public func alamoSmartRequestHeaderGetter(baseURLString: String, apiName: String, dicParams: [String : AnyObject]) -> [String : String]? {
        return nil
    }


    public func alamoSmartCompletionIntercepter(task: URLSessionTask?, response: HTTPURLResponse?, responseObject: AnyObject?, error: Error?, success: AlamoSmartSuccessCallback, failure: AlamoSmartFailureCallback) {
        if let err = error  {
            failure(task,err,responseObject)
        } else {
            success(task,responseObject)
        }
    }

    public func alamoSmartNeedSSLCertificateVerification(baseURLString:String) -> Bool {
        return false
    }

    public func alamoSmartSSLConfigurator() -> [AnyObject]? {
        return nil
    }
    
    public func alamoSmartAuthenticationChallenger(session:URLSession, challenge:URLAuthenticationChallenge, credential:URLCredential) -> URLSession.AuthChallengeDisposition {
        return URLSession.AuthChallengeDisposition.performDefaultHandling
    }
    
    public func alamoSmartNetworkLogInfo(log: String) {
        print(log)
    }

    
}
