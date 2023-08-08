//
//  NZAlamoSmartNetAgent.swift
//  nfzm
//
//  Created by anthony zhu on 2023/4/28.
//  Copyright © 2023 nfzm. All rights reserved.
//

import Foundation
import AlamoSmartNetworking

@objc public enum AlamoSmartNetStatus: NSInteger {
    case Unknown, NotReachable, ConnectViaEthOrWifi, ConnectViaCellular
}


public typealias NZSmartAgentURLConstructor = (NSString, NSMutableDictionary) -> NSString
public typealias NZSmartAgentDestinationBlock = (NSURL?,URLResponse?) -> NSURL
public typealias NZSmartAgentProgressBlock = (Progress) -> ()
public typealias NZSmartAgentSuccessCallback = (URLSessionTask?, AnyObject?) -> ()
public typealias NZSmartAgentFailureCallback = (URLSessionTask?, Error?, AnyObject?) -> ()
public typealias NZSmartMultipartsConstructor = (AWMultipartsFormData) -> ()
public typealias NZSmartNetMonitor = (AlamoSmartNetStatus)->()

@objc class NZAlamoSmartNetAgent : NSObject {
    @objc static let shared = NZAlamoSmartNetAgent()
    override private init(){}
    
    static let defaultDestinationURL: (URL) -> URL = { url in
        let filename = "SmartNetAgent_\(url.lastPathComponent)"
        let destination = url.deletingLastPathComponent().appendingPathComponent(filename)

        return destination
    }
    /**
     发送API请求
     
     @param constructor URLString构造代码块
     @param APIName API请求的服务名
     @param parameters API请求的约定参数
     @param method 请求方法 GET POST 等等
     @param configuration AOP配置
     @param success 请求成功响应
     @param failure 请求失败响应
     @return 返回一个Stub(存根) 通过Stub可以启动/取消该请求 在启动前还可以对请求及响应过程进行定制(例如设置响应信封，设置业务数据模型等等)，同时Stub提供了请求生命周期管理的辅助方法
     */
    @objc public func requestURLEncoding(urlString:NZSmartAgentURLConstructor?,apiName:NSString,parameters:AnyObject?,method:NSString,configuration:NZAlamoSmartNetConfig?,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback, timeout:NSNumber?) -> AlamoSmartNetStub? {
        
        let urlConstructor:AlamoURLConstructor = { (urlStr,parameters) in
            if let agentCon = urlString, let params = parameters {
                return agentCon(NSString(string: urlStr), NSMutableDictionary(dictionary: params)) as String
            }
            return urlStr
        }
        let stub:AlamoSmartRequestStub? = AlamoSmartNetAgent.request(urlConstructor: urlConstructor, apiName: apiName as String, parameters: parameters, method: method as String, encoding: .URLEncodedInURL,configuration: configuration ?? NZAlamoSmartNetConfig.shared, success: success, failure: failure)
        stub?.envelopeCls = envelopeCls
        stub?.modelCls = modelCls
        stub?.dataClas = dataClas
        stub?.timeOutInterval = timeout?.doubleValue ?? 60.0
        stub?.start()
        return AlamoSmartNetStub(stub)
    }
    
    /**
     发送API请求,携带HTTPBody
     
     @param constructor URLString构造代码块
     @param APIName API请求的服务名
     @param parameters API请求的约定参数
     @param method 请求方法 GET POST 等等
     @param httpBody 请求体内容
     @param configuration AOP配置
     @param success 请求成功响应
     @param failure 请求失败响应
     @return 返回一个Stub(存根) 通过Stub可以启动/取消该请求 在启动前还可以对请求及响应过程进行定制(例如设置响应信封，设置业务数据模型等等)，同时Stub提供了请求生命周期管理的辅助方法
     */
    @objc public func requestJsonEncoding(urlString:NZSmartAgentURLConstructor?,apiName:NSString,parameters:AnyObject?,method:NSString,configuration:NZAlamoSmartNetConfig?,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,timeout:NSNumber?) -> AlamoSmartNetStub? {
        
        let urlConstructor:AlamoURLConstructor = { (urlStr,parameters) in
            if let agentCon = urlString, let params = parameters {
                return agentCon(NSString(string: urlStr), NSMutableDictionary(dictionary: params)) as String
            }
            return urlStr
        }
        let stub:AlamoSmartRequestStub? = AlamoSmartNetAgent.request(urlConstructor: urlConstructor, apiName: apiName as String, parameters: parameters,method: method as String, encoding: .JSON,configuration: configuration ?? NZAlamoSmartNetConfig.shared, success: success, failure: failure)
        stub?.envelopeCls = envelopeCls
        stub?.modelCls = modelCls
        stub?.dataClas = dataClas
        stub?.timeOutInterval = timeout?.doubleValue ?? 60.0
        stub?.start()
        return AlamoSmartNetStub(stub)
    }


    /**
     下载请求
     
     @param constructor URLString构造代码块
     @param APIName API请求的服务名
     @param parameters API请求的约定参数
     @param configuration AOP配置
     @param destination 目标路径配置
     @param progress 进度回调block
     @param success 请求成功响应
     @param failure 请求失败响应
     @return 返回一个Stub(存根) 通过Stub可以启动/取消该请求 在启动前还可以对请求及响应过程进行定制(例如设置响应信封，设置业务数据模型等等)，同时Stub提供了请求生命周期管理的辅助方法
     */
    @objc public func download(urlString:NZSmartAgentURLConstructor?,apiName:NSString,parameters:AnyObject?,configuration:NZAlamoSmartNetConfig?,destination: NZSmartAgentDestinationBlock?,progress: NZSmartAgentProgressBlock?, envelopeCls:AnyClass? = nil, modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,timeout:NSNumber?) -> AlamoSmartNetStub? {
        let urlConstructor:AlamoURLConstructor = { (urlStr,parameters) in
            if let agentCon = urlString, let params = parameters {
                return agentCon(NSString(string: urlStr), NSMutableDictionary(dictionary: params)) as String
            }
            return urlStr
        }
        
        let netDestBlock:AlamoSmartDestinationCallback = { (url, response) in
            if let destBlock = destination {
                let destUrl = destBlock(NSURL(string: url.absoluteString), response)
                return URL(string: destUrl.absoluteString ?? "") ?? NZAlamoSmartNetAgent.defaultDestinationURL(url)
            }
            return NZAlamoSmartNetAgent.defaultDestinationURL(url)
        }

        let stub:AlamoSmartRequestStub? = AlamoSmartNetAgent.download(urlConstructor: urlConstructor, apiName: apiName as String, parameters: parameters, configuration: configuration ?? NZAlamoSmartNetConfig.shared, destination:netDestBlock, progress: { completeUnit, totalUnit in
            if let progFunc = progress {
                let prog = Progress()
                prog.completedUnitCount = Int64(completeUnit)
                prog.totalUnitCount = Int64(totalUnit)
                progFunc(prog)
            }
        },success: success,failure: failure)
        stub?.envelopeCls = envelopeCls
        stub?.modelCls = modelCls
        stub?.dataClas = dataClas
        stub?.timeOutInterval = timeout?.doubleValue ?? 120.0
        stub?.start()
        return AlamoSmartNetStub(stub)
    }
    
    /**
     上传数据

     @param constructor URLString构造代码块
     @param APIName API请求的服务名
     @param parameters API请求的约定参数
     @param method 请求方法 GET POST 等等
     @param configuration AOP配置
     @param block 上传文件格式的约束回调[规定表单格式]
     @param progress 进度回调
     @param success 请求成功响应
     @param failure 请求失败响应
     @return 返回一个Stub(存根) 通过Stub可以启动/取消该请求 在启动前还可以对请求及响应过程进行定制(例如设置响应信封，设置业务数据模型等等)，同时Stub提供了请求生命周期管理的辅助方法
     */

    @objc public func upload(urlString:NZSmartAgentURLConstructor?,apiName:NSString,parameters:AnyObject?,method:NSString,configuration:NZAlamoSmartNetConfig?,progress: NZSmartAgentProgressBlock?, constructingBodyWithBlock:@escaping NZSmartMultipartsConstructor,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil, success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,timeout:NSNumber?) -> AlamoSmartNetStub? {
        let urlConstructor:AlamoURLConstructor = { (urlStr,parameters) in
            if let agentCon = urlString, let params = parameters {
                return agentCon(NSString(string: urlStr), NSMutableDictionary(dictionary: params)) as String
            }
            return urlStr
        }
        let stub:AlamoSmartRequestStub? = AlamoSmartNetAgent.upload(urlConstructor: urlConstructor, apiName: apiName as String, parameters: parameters, method: method as String, configuration: configuration ?? NZAlamoSmartNetConfig.shared,constructBodyBlock:constructingBodyWithBlock,progress: { completeUnit, totalUnit in
            if let progFunc = progress {
                let prog = Progress()
                prog.completedUnitCount = Int64(completeUnit)
                prog.totalUnitCount = Int64(totalUnit)
                progFunc(prog)
            }
        },success: success,failure: failure)
        stub?.envelopeCls = envelopeCls
        stub?.modelCls = modelCls
        stub?.dataClas = dataClas
        stub?.timeOutInterval = timeout?.doubleValue ?? 120.0
        stub?.start()
        return AlamoSmartNetStub(stub)
    }
    
    @objc public func startReachabilityMonitoring(listener:@escaping NZSmartNetMonitor) {
        AlamoSmartNetAgent.startMonitoring { status in
            switch status {
            case .Unknown:
                listener(AlamoSmartNetStatus.Unknown)
            case .NotReachable:
                listener(AlamoSmartNetStatus.NotReachable)
            case .ConnectViaEthOrWifi:
                listener(AlamoSmartNetStatus.ConnectViaEthOrWifi)
            case .ConnectViaCellular:
                listener(AlamoSmartNetStatus.ConnectViaCellular)
            }
        }
    }
}

@objc extension NZAlamoSmartNetAgent {
    ///使用缺省配置的GET方法
    @objc public func GET(_ apiName:NSString, parameters:AnyObject?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback, envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?) -> AlamoSmartNetStub?{
        return self.requestURLEncoding(urlString: { apiName, params in
//            var urlStr:String = apiName as String
//            for (key, value) in params {
//                urlStr.urlAddCompnentForValue(with: key as! String, value: value as! String)
//            }
//            return NSString(string: urlStr)
            apiName
        }, apiName: apiName, parameters: parameters, method: "GET", configuration: NZAlamoSmartNetConfig.shared, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas,success: success, failure: failure,timeout: timeout)

        
    }

    ///使用缺省配置的POST方法
    @objc public func POST(_ apiName:NSString, parameters:AnyObject?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback, envelopeCls:AnyClass? = nil, modelCls:AnyClass? = nil, dataClas:AnyClass? = nil,timeout:NSNumber?) -> AlamoSmartNetStub?{
        return self.requestJsonEncoding(urlString: { apiName, _ in
            apiName
        }, apiName: apiName, parameters: parameters, method: "POST", configuration: NZAlamoSmartNetConfig.shared, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure,timeout: timeout)

        
    }

    ///使用缺省配置的PUT方法
    @objc public func PUT(_ apiName:NSString, parameters:AnyObject?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?) -> AlamoSmartNetStub? {
        return self.requestJsonEncoding(urlString: { apiName, _ in
            apiName
        }, apiName: apiName, parameters: parameters, method: "PUT", configuration: NZAlamoSmartNetConfig.shared, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure,timeout: timeout)

    }

    ///使用缺省配置的DELETE方法
    @objc public func DELETE(_ apiName:NSString, parameters:AnyObject?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?) -> AlamoSmartNetStub? {
        return self.requestURLEncoding(urlString: { apiName, _ in
            apiName
        }, apiName: apiName, parameters: parameters, method: "DELETE", configuration: NZAlamoSmartNetConfig.shared, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure,timeout: timeout)

    }
    
    ///使用缺省配置的HEAD方法
    @objc public func HEAD(_ apiName:NSString, parameters:AnyObject?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?)-> AlamoSmartNetStub? {
        return self.requestURLEncoding(urlString: { apiName, _ in
            apiName
        }, apiName: apiName, parameters: parameters, method: "HEAD", configuration: NZAlamoSmartNetConfig.shared, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure,timeout: timeout)
    }

    ///使用缺省配置的DOWNLOAD方法
    @objc public func DOWNLOAD(_ url:NSString, destination: NZSmartAgentDestinationBlock?,progress: NZSmartAgentProgressBlock?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?) -> AlamoSmartNetStub? {
        return self.download(urlString: { apiName, _ in
            apiName
        }, apiName: url, parameters: nil, configuration: NZAlamoSmartNetConfig.shared, destination: destination, progress: progress, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure, timeout: timeout)
    }

    ///使用缺省配置的UPLOAD方法
    @objc public func UPLOAD(_ apiName:NSString, parameters:AnyObject?,method:NSString, constructingBodyWithBlock:@escaping NZSmartMultipartsConstructor, progress: NZSmartAgentProgressBlock?,success:@escaping NZSmartAgentSuccessCallback, failure:@escaping NZSmartAgentFailureCallback,envelopeCls:AnyClass? = nil,modelCls:AnyClass? = nil,dataClas:AnyClass? = nil,timeout:NSNumber?)-> AlamoSmartNetStub? {
        return self.upload(urlString: { apiName, _ in
            apiName
        }, apiName: apiName, parameters: parameters, method: method, configuration: NZAlamoSmartNetConfig.shared, progress:progress , constructingBodyWithBlock: constructingBodyWithBlock, envelopeCls: envelopeCls, modelCls: modelCls, dataClas: dataClas, success: success, failure: failure,timeout: timeout)
        
    }
}

@objc public class AlamoSmartNetStub : NSObject {
    private var stub:AlamoSmartRequestStub?
    init(_ stub: AlamoSmartRequestStub? = nil) {
        self.stub = stub
    }
    @objc public func start() {
        stub?.start()
    }
    @objc public func cancel() {
        stub?.cancel()
    }
}


//extension String {
//    mutating func urlAddCompnentForValue(with key: String, value: String) {
//        //先判断链接是否带？
//        if self.contains("?") {
//            //?号是否在最后一个字符
//            if self.last == "?" {
//                self += "\(key)=\(value)"
//            } else {
//                //最后一个字符是否是&
//                if self.last == "&" {
//                    self += "\(key)=\(value)"
//                } else {
//                    self += "&\(key)=\(value)"
//                }
//            }
//        } else {
//            //不带问号
//            self += "?\(key)=\(value)"
//        }
//    }
//}
