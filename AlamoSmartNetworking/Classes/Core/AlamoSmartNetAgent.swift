//
//  AlamoSmartNetAgent.swift
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/4/27.
//

import Foundation
import Alamofire

open class AlamoSmartNetAgent {
    public static let dispatchQueue = DispatchQueue(label: "com.infzm.infzm.alamoSmartNetAgetn.completion-queue")
    
    //fileprivate static var stubHandlers:Dictionary<String,(AlamoSmartRequestStub,AlamoSmartRequestSyncConstructor?)> = [:]
    /// defaultSession with timeout 60s ,cachepolicy ignore local cachedata, request should use
    /// pipeline and not set cookies
    //static let lock = NSLock()
    public static let `defaultSession`:Session = {
        let config:URLSessionConfiguration = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 60;
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpShouldUsePipelining = true
        config.httpShouldSetCookies = false
//        let eventMonitor = ClosureEventMonitor()
//        eventMonitor.requestDidCreateURLRequest = { (Request, URLRequest) in
//            print(Request.cURLDescription())
//            if let URLString = URLRequest.url?.absoluteString, let (_,handler) = stubHandlers[URLString] {
//                handler?(Request)
//                stubHandlers[URLString] = nil
//            }
//        }
//        return Session(configuration:config, rootQueue:dispatchQueue,eventMonitors:[eventMonitor])
        return Session(configuration:config, rootQueue:dispatchQueue)

    }()
    /// ServerTrustSession with timeout 60s and public key trust based on host
    public static let `serverTrustSession`:Session = {
        /// serverTrustSession with timeout 60s ,cachepolicy ignore local cachedata, request should use pipeline and not set cookies
        let config:URLSessionConfiguration = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 60;
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpShouldUsePipelining = true
        config.httpShouldSetCookies = false
        let secTrustEval:PublicKeysTrustEvaluator = PublicKeysTrustEvaluator(validateHost: true)
        let secTrustManager:ServerTrustManager = ServerTrustManager(allHostsMustBeEvaluated:false, evaluators: ["xxx.xxx.com":secTrustEval,"yyy.xxx.com":secTrustEval])
        return Session(configuration: config,rootQueue: dispatchQueue, serverTrustManager: secTrustManager)
    }()
    /// downloadSession with timeout 120s
    public static let `downloadSession`:Session = {
        let config:URLSessionConfiguration = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 120;
        return Session(configuration: config, rootQueue: dispatchQueue)
    }()
    /// uploadSession with timeout 120s
    public static let `uploadSession`:Session = {
        let config:URLSessionConfiguration = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 120;
        return Session(configuration: config, rootQueue: dispatchQueue)
    }()
    
    /// Reachablity manager for host www.apple.com
    public static let reachability:NetworkReachabilityManager? = NetworkReachabilityManager(host:"www.apple.com")
    
    static func baseURLStringWithURLString(URLString:String) -> String {
        let url:URL? = URL(string: URLString)
        guard let scheme = url?.scheme, let host = url?.host else {
            return ""
        }
        var baseURLString:String = scheme + "://" + host
        if let port = url?.port {
            baseURLString = baseURLString + ":" + String(port)
        }
        return baseURLString
    }
    
    static public func request(urlConstructor:AlamoURLConstructor?, apiName:String, parameters:AnyObject?, method:String,encoding:RequestParameterEncoding = RequestParameterEncoding.URLEncodedInURL,configuration:AlamoSmartConfigurationProtocol, success:@escaping AlamoSmartSuccessCallback, failure:@escaping AlamoSmartFailureCallback) -> AlamoSmartRequestStub? {
        guard let constructor = urlConstructor else {
            return nil
        }
        var useSession = defaultSession
        
        var dicParams:[String:AnyObject] = [:]
        if let param = parameters {
            dicParams = configuration.alamoSmartParameterSerializer(parameters: param) ?? [:]
        }
        var URLString = constructor(apiName, dicParams)
        URLString = configuration.alamoSmartURLStringConstructor(urlString: URLString, apiName: apiName)
        
        let baseURLString = self.baseURLStringWithURLString(URLString: URLString)
        
        if configuration.alamoSmartNeedSSLCertificateVerification(baseURLString: baseURLString) {
            useSession = serverTrustSession
        }
        
        var signature = ""
        dicParams = configuration.alamoSmartOAuthConfigurator(dicParams: dicParams, apiName: apiName, signature: &signature)
        
        var reqHeaders:[String:String]?
        reqHeaders = configuration.alamoSmartRequestHeaderGetter(baseURLString: baseURLString, apiName: apiName, dicParams: dicParams)
        var dicHeaders:[String:String] = ["Cookie":"","Accept-Encoding":"gzip","Content-Type":"application/json"]
        if let headers = reqHeaders {
            dicHeaders = dicHeaders.merging(headers) {$1}
        }
        
        configuration.alamoSmartNetworkLogInfo(log: "\n===AlamoSmartNetWorking Request===\n<<<URL: \(URLString) \n<<<METHOD: \(method) \n<<<PARAMS:  \(dicParams) \n<<<Headers:  \(reqHeaders ?? [:]) \n<<<Encoding: \(encoding)")


        let stub:AlamoSmartRequestStub = AlamoSmartRequestStub(apiName: apiName, config: configuration, success: success, failure: failure) { reqConstructor, taskAsyncConstructor, completeHandler in
            let request = self.dataTask(session: useSession,
                                    method: method,
                                    urlString: URLString,
                                    parameters:dicParams,
                                    encoding: encoding,
                                    headers:dicHeaders,
                                    constructor: taskAsyncConstructor) { response, json in
               completeHandler(response,json,nil)
            } failure: { response, error in
                completeHandler(response,nil,error)
            }

//            lock.lock()
//            if let (stub,_) = stubHandlers[URLString] {
//                stubHandlers[URLString] = (stub, reqConstructor)
//            }
//            lock.unlock()
            reqConstructor(request)
        }
//        lock.lock()
//        stubHandlers[URLString] = (stub, nil)
//        lock.unlock()
        //stub.start()
        return stub
    }
    
    static public func download(urlConstructor:AlamoURLConstructor?, apiName:String, parameters:AnyObject?, configuration:AlamoSmartConfigurationProtocol, destination:@escaping AlamoSmartDestinationCallback,progress:@escaping AlamoSmartProgressCallback, success:@escaping AlamoSmartSuccessCallback, failure:@escaping AlamoSmartFailureCallback) -> AlamoSmartRequestStub? {
        guard let constructor = urlConstructor else {
            return nil
        }
        var useSession = downloadSession
        
        var dicParams:[String:AnyObject] = [:]
        if let param = parameters {
            dicParams = configuration.alamoSmartParameterSerializer(parameters: param) ?? [:]
        }
        var URLString = constructor(apiName, dicParams)
        URLString = configuration.alamoSmartURLStringConstructor(urlString: URLString, apiName: apiName)
        
        let baseURLString = self.baseURLStringWithURLString(URLString: URLString)
        
        if configuration.alamoSmartNeedSSLCertificateVerification(baseURLString: baseURLString) {
            useSession = serverTrustSession
        }
        
        let dicDefParams = configuration.alamoSmartDefaultParameterGetter(baseURLString: baseURLString, apiName: apiName, dicParams: dicParams)
        if let defParams = dicDefParams {
            dicParams = dicParams.merging(defParams) { $1 }
        }
        
        var signature = ""
        dicParams = configuration.alamoSmartOAuthConfigurator(dicParams: dicParams, apiName: apiName, signature: &signature)
        
        let reqHeaders = configuration.alamoSmartRequestHeaderGetter(baseURLString: baseURLString, apiName: apiName, dicParams: dicParams)
        
        configuration.alamoSmartNetworkLogInfo(log: "\n===AlamoSmartNetWorking Download===\n<<<URL: \(URLString) \n<<<PARAMS:  \(dicParams) \n<<<Headers:  \(reqHeaders ?? [:]) ")

        let stub:AlamoSmartRequestStub = AlamoSmartRequestStub(apiName: apiName, config: configuration, success: success, failure: failure) { reqConstructor, taskAsyncConstructor, completeHandler in
            let request = self.downloadDataTask(session: useSession, method:"GET", urlString: URLString,headers:reqHeaders, progressBlock: progress, destination: destination, constructor: taskAsyncConstructor) { response, json in
                completeHandler(response,json,nil)
            } failure: { response, error in
                completeHandler(response,nil,error)
            }
            reqConstructor(request)
        }
        //stub.start()
        return stub
    }
    
    static public func upload(urlConstructor:AlamoURLConstructor?, apiName:String, parameters:AnyObject?,method:String, configuration:AlamoSmartConfigurationProtocol, constructBodyBlock:@escaping AlamoAgentMultipartDataConstructor, progress:@escaping AlamoSmartProgressCallback, success:@escaping AlamoSmartSuccessCallback, failure:@escaping AlamoSmartFailureCallback) -> AlamoSmartRequestStub? {
        
        guard let constructor = urlConstructor else {
            return nil
        }
        var useSession = uploadSession
        
        var dicParams:[String:AnyObject] = [:]
        if let param = parameters {
            dicParams = configuration.alamoSmartParameterSerializer(parameters: param) ?? [:]
        }
        var URLString = constructor(apiName, dicParams)
        URLString = configuration.alamoSmartURLStringConstructor(urlString: URLString, apiName: apiName)
        
        let baseURLString = self.baseURLStringWithURLString(URLString: URLString)
        
        if configuration.alamoSmartNeedSSLCertificateVerification(baseURLString: baseURLString) {
            useSession = serverTrustSession
        }
        
        var signature = ""
        dicParams = configuration.alamoSmartOAuthConfigurator(dicParams: dicParams, apiName: apiName, signature: &signature)
        
        let reqHeaders:[String:String]?
        reqHeaders = configuration.alamoSmartRequestHeaderGetter(baseURLString: baseURLString, apiName: apiName, dicParams: dicParams)
        
        configuration.alamoSmartNetworkLogInfo(log: "\n===AlamoSmartNetWorking Upload===\n<<<URL: \(URLString) \n<<<METHOD: \(method) \n<<<PARAMS:  \(dicParams) \n<<<Headers:  \(reqHeaders ?? [:]) ")
        
        let stub:AlamoSmartRequestStub = AlamoSmartRequestStub(apiName: apiName, config: configuration, success: success, failure: failure) { reqConstructor, taskAsyncConstructor, completeHandler in
            let request = self.uploadDataTask(session: useSession, urlString: URLString, headers:reqHeaders, multipartFormData: { MultipartDataWrapper in
                let formData:AlamoWrapperMulPartsFormData = AlamoWrapperMulPartsFormData()
                formData.appendParameters(dicParams)
                constructBodyBlock(formData)
                formData.convert(toMulParsDataWrapper: MultipartDataWrapper)

            }, progressBlock: progress, constructor: taskAsyncConstructor) { response, json in
                completeHandler(response,json,nil)
            } failure: { response, error in
                completeHandler(response,nil,error)
            }
            reqConstructor(request)
        }
        //stub.start()
        return stub
        
    }
}

// MARK: - 数据任务处理
extension AlamoSmartNetAgent {
    /**
    func to setup a datatask based on session type selected.
    - Parameter  sessionType:SessionType session type selected
    - Parameter  method:request method
    - Parameter  urlString:request url
    - Parameter  parameters:request parameters
    - Parameter  encoding:request parameters encoding
    - Parameter  headers:request headers
    - Parameter  httpBody:request body data
    - Parameter  constructor:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */
    public class func dataTask(
        session:Session,
        method: String,
        urlString: String,
        parameters: [String: AnyObject]? = nil,
        encoding: RequestParameterEncoding = .URLEncodedInURL,
        headers: [String: String]? = nil,
        httpBody: Data? = nil,
        constructor: @escaping (_ task: URLSessionTask) -> (),
        success: @escaping (_ response: HTTPURLResponse?,_ json: AnyObject?) -> (),
        failure: @escaping (_ response: HTTPURLResponse?,_ error: Error?) -> ()) -> Request {
            let method = translateMethod(method:method)
            let encoding = translateEncoding(encoding: encoding)
            var httpHeaders:HTTPHeaders?
            if let hs = headers {
                httpHeaders = HTTPHeaders.init(hs)
            }
            let keyCount = parameters?.keys.count ?? 0
            let request:DataRequest = session.request(urlString,method: method,parameters: keyCount > 0 ? parameters : nil,encoding:encoding, headers: httpHeaders,requestModifier: { URLRequest in
                        if let body = httpBody {
                            URLRequest.httpBody = body
                        }
                }).validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml"])
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
            return request
    }
    
    /**
    objc public  func to setup a download connection.
    - Parameter  sessionType:choose a preset urlSession based on type
    - Parameter  method:request method
    - Parameter  urlString:request url string
    - Parameter  encoding:request parameter encoding
    - Parameter  headers:request headers
    - Parameter  progressBlock:upload progress block
    - Parameter  destination:target path constructor
    - Parameter  constructor:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */
    public class func downloadDataTask(session: Session,
                                            method: String,
                                          urlString: String,
                                         parameters: [String: AnyObject]? = nil,
                                           encoding: RequestParameterEncoding = .JSON,
                                            headers: [String: String]? = nil,
                                       progressBlock: @escaping ((_ cur: Float, _ total:Float) -> ()),
                                         destination: @escaping ((_ targetPath:URL, _ response:HTTPURLResponse) -> URL),
                                         constructor: @escaping ((_ task: URLSessionTask) -> Void),
                                            success: @escaping (_ response: HTTPURLResponse?,_ json: AnyObject?) -> (),
                                            failure: @escaping (_ response: HTTPURLResponse?,_ error: Error?) -> ()) -> Request {
        let method = translateMethod(method:method)
        let encoding = translateEncoding(encoding: encoding)
        var httpHeaders:HTTPHeaders?
        if let hs = headers {
            httpHeaders = HTTPHeaders.init(hs)
        }
        let downloadRequest:DownloadRequest = session.download(urlString,method:method,parameters: parameters,encoding:encoding, headers: httpHeaders, to: { temporaryURL, response in
            return (destination(temporaryURL, response),.createIntermediateDirectories)
        }).downloadProgress{Progress in progressBlock(Float(Progress.completedUnitCount),Float(Progress.totalUnitCount))}
        downloadRequest.validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml","application/pdf"])
        ///download response not jsondecoder or propertylistdecoder, use raw data without decoded
        downloadRequest.response { (response)->Void in
            parseDownloadResponse(response: response, success: success, failure: failure)
        }
        downloadRequest.onURLSessionTaskCreation { URLSessionTask in
            constructor(URLSessionTask)
        }
        return downloadRequest
    }
    
    public class func uploadDataTask(
        session:Session,
        urlString: String,
        headers: [String: String]? = nil,
        multipartFormData: @escaping AlamoSmartMultipartDataConstructor,
        progressBlock: @escaping AlamoSmartProgressCallback,
        constructor: @escaping ((_ task: URLSessionTask) -> Void),
        success: @escaping ((_ response: HTTPURLResponse?,_ json: AnyObject?) -> Void) ,
        failure: @escaping ((_ response: HTTPURLResponse?,_ error: Error?) -> Void)) -> Request {
            var httpHeaders:HTTPHeaders?
            if let hs = headers {
                httpHeaders = HTTPHeaders.init(hs)
            }
            let request:UploadRequest = session.upload(multipartFormData:{ MultipartFormData in
                let bodyParts:MultipartDataWrapper = MultipartDataWrapper()
                multipartFormData(bodyParts)
                for part in bodyParts.parts {
                    switch part.appType {
                    case .fileUrl_name:
                        MultipartFormData.append(part.fileUrl!, withName:part.name!)
                    case .fileUrl_name_fileName_mimeType:
                        MultipartFormData.append(part.fileUrl!, withName:part.name!, fileName: part.fileName!, mimeType: part.mimeType!)
                    case .iSData_name_fileName_length_mimeType:
                        MultipartFormData.append(part.inputStream!, withLength: part.length,name: part.name!,fileName: part.fileName!,mimeType: part.mimeType!)
                    case .iSUrl_name_fileName_length_mimeType:
                        MultipartFormData.append(part.inputStream!, withLength: part.length,name: part.name!,fileName: part.fileName!,mimeType: part.mimeType!)
                    case .fileData_name_fileName_mimeType:
                        MultipartFormData.append(part.fileData!,withName: part.name!,fileName: part.fileName!,mimeType: part.mimeType!)
                    case .formData_name:
                        MultipartFormData.append(part.formData!, withName: part.name!)
                    case .headers_bodyData:
                        MultipartFormData.append(part.inputStream!, withLength: part.length,headers: part.headers!)
                    case .unknowned:
                        break;
                    }
                }
            }, to:urlString,headers: httpHeaders).uploadProgress { Progress in
                progressBlock(Float(Progress.completedUnitCount),Float(Progress.totalUnitCount))
            }
            
            request.validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml","application/pdf"])
            
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
            
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
            return request
    }

}

// MARK: - 网络监听
extension AlamoSmartNetAgent {
    @objc public class func startMonitoring(listener:@escaping (_ netStatus:AlamoFireNetStatus) -> Void) {
        switch (self.reachability?.status) {
        case .unknown:
            listener(.Unknown)
        case .notReachable:
            listener(.NotReachable)
        case .reachable(let connectType):
            switch connectType {
            case .ethernetOrWiFi:
                listener(.ConnectViaEthOrWifi)
            case .cellular:
                listener(.ConnectViaCellular)
            }
        case .none:
            listener(.Unknown)
        }
        self.reachability?.startListening(onUpdatePerforming: { Reachablity in
            switch (Reachablity) {
            case .unknown:
                listener(.Unknown)
            case .notReachable:
                listener(.NotReachable)
            case .reachable(let connectType):
                switch connectType {
                case .ethernetOrWiFi:
                    listener(.ConnectViaEthOrWifi)
                case .cellular:
                    listener(.ConnectViaCellular)
                }
            }
        })

    }
}

// MARK: - 类型数据处理
extension AlamoSmartNetAgent {
    // MARK: - Private Methods
    ///convert objc method string to alamofire httpmethod
    private class func translateMethod(method: String) -> HTTPMethod {
        if (method == "GET") {
            return .get
        } else if (method == "POST") {
            return .post
        } else if (method == "DELETE") {
            return .delete
        } else if (method == "HEAD") {
            return .head
        } else if (method == "PUT") {
            return .put
        } else if (method == "PATCH") {
            return .patch
        } else if (method == "TRACE") {
            return .trace
        } else if (method == "CONNECT") {
            return .connect
        } else if (method == "OPTIONS") {
            return .options
        }
        return .get
    }
    ///convert objc parameters encoding to alamofire parameterencoding
    private class func translateEncoding(encoding: RequestParameterEncoding) -> Alamofire.ParameterEncoding {
        switch (encoding) {
        case .JSON:
            return JSONEncoding.default
        case .URLEncodedInURL:
            return URLEncoding.default
        case .URL:
            return URLEncoding.default
        }
    }
    ///json parse response
    private class func parseResponse(response: AFDataResponse<Empty>, success: (_ response: HTTPURLResponse?, _ json: AnyObject?) -> (),
                                     failure: (_ response: HTTPURLResponse?, _ error: Error?) -> ()) {
            switch (response.result) {
            case .success:
                if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) {
                    success(response.response, json as AnyObject)
                } else {
                    success(response.response, nil)
                }
            case .failure:
                failure(response.response, response.error as Error?)
            }
    }
    ///json parse download response
    private class func parseDownloadResponse(response: AFDownloadResponse<URL?>, success: (_ response: HTTPURLResponse?, _ json: AnyObject?) -> (),
                                     failure: (_ response: HTTPURLResponse?, _ error: Error?) -> ()) {
            switch (response.result) {
            case .success:
                success(response.response, nil)
            case .failure:
                failure(response.response, response.error as Error?)
            }
    }

}
