//
//  AlamofireWrapper.swift
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/3/21.
//

import Foundation
import Alamofire

// MARK: objc enum bridging

/// Reachability of the `AlamoFire`,used as objc bridge definition of states.
/// State `Unkonwn` , initial state. State`NotReachable`,network can not be reached.State ConnectViaEthOrWifi', network is connected by ethent or wifi. State `ConnectViaCellular`, network is connected by cellular as 4G or 5G for example.
@objc public enum AlamoFireNetStatus: NSInteger {
    case Unknown, NotReachable, ConnectViaEthOrWifi, ConnectViaCellular
}

/// Request Parameters Encoding Method.used as objc bridge definition for parameter encoding.
@objc public enum RequestParameterEncoding: NSInteger {
    case URL, URLEncodedInURL, JSON
}

/// Alamofire Session Type , used as objc bridge for different type session used .
/// Type `Default`, Alamofire Session Default. Type 'ServerTrust', initialize https linke with ServerTrustManager for certification verification. Type `DownLoad`, initialized for download link. Type `Upload`, initialzied for upload link.
@objc public enum SessionType: NSInteger {
    case Defualt, ServerTrust, DownLoad, UpLoad
}

// MARK: alamofire multipart data constructing
/// mark the append methods for constructing AFMultiPartsData from objc, which used to covert to append methods for constructing alamofire MultipartFormData .
enum AppendType {
    case fileUrl_name, fileUrl_name_fileName_mimeType,iSData_name_fileName_length_mimeType,iSUrl_name_fileName_length_mimeType,fileData_name_fileName_mimeType,formData_name,headers_bodyData,unknowned
}

class MultipartData {
    var appType:AppendType = .unknowned
    var fileUrl:URL?
    var name:String?
    var fileName:String?
    var length:UInt64 = 0
    var mimeType:String?
    var inputStream:InputStream?
    var fileData:Data?
    var formData:Data?
    var headers:HTTPHeaders?
    var bodyData:Data?
}
@objc public class MultipartDataWrapper : NSObject {
    var parts:[MultipartData] = Array()
    
    ///the same method in afnetworking with fileURL & name
    @objc public func appendPart(fileURL:NSURL, name:String) -> Bool {
        let urlString: String? = fileURL.absoluteString
        if let urlSObject = urlString {
            let url:URL? = URL(string:urlSObject)
            if let urlObject = url {
                //multipartData.append(urlObject, withName:name)
                let part:MultipartData = MultipartData()
                part.appType = .fileUrl_name
                part.fileUrl = urlObject
                part.name = name
                self.parts.append(part)
                return true
            }
        }
        return false
    }
    ///the same method in afnetworking with fileURL & name & fileName&mimeType
    @objc public func appendPart(fileURL:NSURL,name:String,fileName:String,mimeType:String) -> Bool {
        let urlString: String? = fileURL.absoluteString
        if let urlSObject = urlString {
            let url:URL? = URL(string:urlSObject)
            if let urlObject = url {
                //multipartData.append(urlObject, withName:name, fileName: fileName, mimeType: mimeType)
                let part:MultipartData = MultipartData()
                part.appType = .fileUrl_name_fileName_mimeType
                part.fileUrl = urlObject
                part.name = name;
                part.fileName = fileName
                part.mimeType = mimeType
                self.parts.append(part)
                return true
            }
        }
        return false
    }
    ///the same method in afnetworking with inputStream with data & name & fileName & length  & mimeType
    @objc public func appendPart(inputStreamdata:Data,name:String,fileName:String,length:UInt64,mimeType:String) {
        let part:MultipartData = MultipartData()
        let inputS:InputStream = InputStream(data: inputStreamdata)
        part.appType = .iSData_name_fileName_length_mimeType
        part.inputStream = inputS
        part.name = name
        part.fileName = fileName
        part.length = length
        part.mimeType = mimeType
        self.parts.append(part)
        //multipartData.append(inputS, withLength: length,name: name,fileName: fileName,mimeType: mimeType)
    }

    ///the same method in afnetworking with inputStream with url & name & fileName & length  & mimeType
    @objc public func appendPart(inputStreamUrl:NSURL,name:String,fileName:String,length:UInt64,mimeType:String) -> Bool {
        let urlString: String? = inputStreamUrl.absoluteString
        if let urlSObject = urlString {
            let url:URL? = URL(string:urlSObject)
            if let urlObject = url {
                let inputS:InputStream? = InputStream(url: urlObject)
                if let input = inputS {
                    let part:MultipartData = MultipartData()
                    part.appType = .iSUrl_name_fileName_length_mimeType
                    part.inputStream = input
                    part.name = name
                    part.fileName = fileName
                    part.length = length
                    part.mimeType = mimeType
                    self.parts.append(part)
                    //multipartData.append(input, withLength: length,name: name,fileName: fileName,mimeType: mimeType)
                    return true
                }
            }
        }
        return false
    }

    ///the same method in afnetworking with fileData  & name & fileName & length  & mimeType
    @objc public func appendPart(fileData:Data,name:String,fileName:String,mimeType:String) {
        let part:MultipartData = MultipartData()
        part.appType = .fileData_name_fileName_mimeType
        part.fileData = fileData
        part.name = name
        part.fileName = fileName
        part.mimeType = mimeType
        self.parts.append(part)
        //multipartData.append(fileData,withName: name,fileName: fileName,mimeType: mimeType)
    }

    ///the same method in afnetworking with data  & name
    @objc public func appendPart(formData:Data,name:String) {
        let part:MultipartData = MultipartData()
        part.appType = .formData_name
        part.formData = formData
        part.name = name
        self.parts.append(part)
        //multipartData.append(formData, withName: name)
    }
    
    ///the same method in afnetworking with headers & body
    @objc public func appendPart(headers:[String:String],body:Data) {
        let part:MultipartData = MultipartData()
        part.appType = .headers_bodyData
        let inputS:InputStream = InputStream(data: body)
        part.inputStream = inputS
        part.length = UInt64(body.count)
        part.headers = HTTPHeaders(headers)
        self.parts.append(part)
        //multipartData.append(inputS, withLength: UInt64(body.count),headers: HTTPHeaders(headers))
    }
}

// MARK: wrapper for objc
public class AlamofireWrapper: NSObject {
    public static let dispatchQueue = DispatchQueue(label: "com.infzm.infzm.alamofirewrapper.completion-queue")
    /// defaultSession with timeout 60s ,cachepolicy ignore local cachedata, request should use pipeline and not set cookies
    public static let `defaultSession`:Session = {
        let config:URLSessionConfiguration = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 60;
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpShouldUsePipelining = true
        config.httpShouldSetCookies = false
        return Session(configuration: config, rootQueue:dispatchQueue)
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
    // MARK: - Request Methods
    
    /**
    Creates a request using the shared manager instance for the specified method, URL string, parameters, and
    parameter encoding.
    
    - parameter method:     The HTTP method.
    - parameter URLString:  The URL string.
    - parameter parameters: The parameters. `nil` by default.
    - parameter encoding:   The parameter encoding. `.URL` by default.
    - parameter headers:    The HTTP headers. `nil` by default.
    - parameter success:    Block to be called in case of successful execution of the request.
    - parameter failure:    Block to be called in case of errors during the execution of the request.
    */
    @objc public class func request(
        method: String,
        URLString: String,
        parameters: [String: NSObject]? = nil,
        encoding: RequestParameterEncoding = .URL,
        headers: [String: String]? = nil,
        success: @escaping (_ response: HTTPURLResponse?,_ json: Any?) -> (),
        failure: @escaping (_ response: HTTPURLResponse?,_ error: NSError?) -> ()) {
            
            let method = translateMethod(method:method)
            let encoding = translateEncoding(encoding: encoding)
            var httpH:HTTPHeaders?
            if let hs = headers {
                httpH = HTTPHeaders.init(hs)
            }
            let request:DataRequest
            request = AF.request(URLString,method:method,parameters:parameters,encoding:encoding,headers:httpH)
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
    }
    
    /**
    objc public func to run a the preset session.
    
    - Parameter  type:choosed session type
    - Returns URLSession for objc class
    */
    @objc public class func session(type:SessionType) -> URLSession {
        switch type {
        case .Defualt:
            return defaultSession.session
        case .ServerTrust:
            return serverTrustSession.session
        case .DownLoad:
            return downloadSession.session
        case .UpLoad:
            return uploadSession.session
        }
    }

    /**
    private func to get a the preset session based on type selected.
    
    - Parameter  type:choosed session type
    - Returns Alamofire Session
    */
    public class func session(type:SessionType) -> Session {
        switch type {
        case .Defualt:
            return defaultSession
        case .ServerTrust:
            return serverTrustSession
        case .DownLoad:
            return downloadSession
        case .UpLoad:
            return uploadSession
        }
    }
    
    // MARK: - public data task Methods
    /**
    objc public  func to setup a datatask based on session type selected.
    - Parameter  type:SessionType session type selected
    - Parameter  origRequest:objc original nsurlrequest
    - Parameter  origRequest:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */
    @objc public class func dataTask(
        sessionType:SessionType,
        origRequest:URLRequest,
        constructor: @escaping (_ task: URLSessionTask) -> (),
        success: @escaping (_ response: HTTPURLResponse?,_ json: Any?) -> (),
        failure: @escaping (_ response: HTTPURLResponse?,_ error: NSError?) -> ())  {
            let request:DataRequest = self.session(type: sessionType).request(origRequest).validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml"])
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
    }

    /**
    objc public  func to setup a datatask based on session type selected.
    - Parameter  sessionType:SessionType session type selected
    - Parameter  method:request method
    - Parameter  urlString:request url
    - Parameter  parameters:request parameters
    - Parameter  encoding:request parameters encoding
    - Parameter  headers:request headers
    - Parameter  constructor:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */
    @objc public class func dataTask(
        sessionType:SessionType,
        method: String,
        urlString: String,
        parameters: [String: NSObject]? = nil,
        encoding: RequestParameterEncoding = .JSON,
        headers: [String: String]? = nil,
        constructor: @escaping (_ task: URLSessionTask) -> (),
        success: @escaping (_ response: HTTPURLResponse?,_ json: Any?) -> (),
        failure: @escaping (_ response: HTTPURLResponse?,_ error: NSError?) -> ())  {
            let method = translateMethod(method:method)
            let encoding = translateEncoding(encoding: encoding)
            var httpHeaders:HTTPHeaders?
            if let hs = headers {
                httpHeaders = HTTPHeaders.init(hs)
            }
            let request:DataRequest = self.session(type: sessionType).request(urlString,method: method,parameters: parameters,encoding:encoding, headers: httpHeaders).validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml"])
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
    }

    // MARK: - Upload Methods
    /**
    objc public  func to setup a upload connection.
    - Parameter  origRequest:upload nsurlrequest
    - Parameter  multipartFormData:multipart body data constructor
    - Parameter  progressBlock:upload progress block
    - Parameter  constructor:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */

    @objc public class func uploadDataTask(
        origRequest:URLRequest,
        multipartFormData: @escaping (MultipartDataWrapper) -> Void,
        progressBlock: @escaping ((_ cur: Float, _ total:Float) -> ()),
        constructor: @escaping ((_ task: URLSessionTask) -> Void),
        success: @escaping ((_ response: HTTPURLResponse?,_ json: Any?) -> Void) ,
        failure: @escaping ((_ response: HTTPURLResponse?,_ error: NSError?) -> Void))  {
            let request:UploadRequest = self.uploadSession.upload(multipartFormData:{ MultipartFormData in
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
            }, with: origRequest).uploadProgress { Progress in
                progressBlock(Float(Progress.completedUnitCount),Float(Progress.totalUnitCount))
            }
            
            request.validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml","application/pdf"])
            
            request.responseDecodable(of:Empty.self) { (response) -> Void in
                parseResponse(response: response, success: success, failure: failure)
            }
            
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
    }

    // MARK: - download Methods
    /**
    objc public  func to setup a download connection.
    - Parameter  origRequest:upload nsurlrequest
    - Parameter  progressBlock:upload progress block
    - Parameter  destination:target path constructor
    - Parameter  constructor:asynchornized task construct function
    - Parameter  success:data task success callback
    - Parameter  failure:data task failure callback
    */

    @objc public class func downloadDataTask(
        origRequest:URLRequest,
        progressBlock: @escaping ((_ cur: Float, _ total:Float) -> ()),
        destination: @escaping ((_ targetPath:URL, _ response:HTTPURLResponse) -> URL),
        constructor: @escaping ((_ task: URLSessionTask) -> Void),
        success: @escaping (_ response: HTTPURLResponse?,_ json: Any?) -> (),
        failure: @escaping (_ response: HTTPURLResponse?,_ error: NSError?) -> ()) {
            let request:DownloadRequest = self.downloadSession.download(origRequest) { temporaryURL, response in
                return (destination(temporaryURL, response),.createIntermediateDirectories)
            }.downloadProgress { Progress in
                progressBlock(Float(Progress.completedUnitCount),Float(Progress.totalUnitCount))
            }
            request.validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml","application/pdf"])
            ///download response not jsondecoder or propertylistdecoder, use raw data without decoded
            request.response { (response)->Void in
                parseDownloadResponse(response: response, success: success, failure: failure)
            }
//            request.responseDecodable(of:Empty.self) { (response) -> Void in
//                parseDownloadResponse(response: response, success: success, failure: failure)
//            }
            request.onURLSessionTaskCreation { URLSessionTask in
                constructor(URLSessionTask)
            }
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
    @objc public class func downloadDataTask(sessionType: SessionType,
                                            method: String,
                                          urlString: String,
                                         parameters: [String: NSObject]? = nil,
                                           encoding: RequestParameterEncoding = .JSON,
                                            headers: [String: String]? = nil,
                                       progressBlock: @escaping ((_ cur: Float, _ total:Float) -> ()),
                                         destination: @escaping ((_ targetPath:URL, _ response:HTTPURLResponse) -> URL),
                                         constructor: @escaping ((_ task: URLSessionTask) -> Void),
                                            success: @escaping (_ response: HTTPURLResponse?,_ json: Any?) -> (),
                                            failure: @escaping (_ response: HTTPURLResponse?,_ error: NSError?) -> ()) {
        let method = translateMethod(method:method)
        let encoding = translateEncoding(encoding: encoding)
        var httpHeaders:HTTPHeaders?
        if let hs = headers {
            httpHeaders = HTTPHeaders.init(hs)
        }
        let downloadRequest:DownloadRequest = self.session(type: sessionType).download(urlString,method:method,parameters: parameters,encoding:encoding, headers: httpHeaders, to: { temporaryURL, response in
            return (destination(temporaryURL, response),.createIntermediateDirectories)
        }).downloadProgress{Progress in progressBlock(Float(Progress.completedUnitCount),Float(Progress.totalUnitCount))}
        downloadRequest.validate(contentType: ["application/json","text/json", "text/javascript","text/html","text/plain","text/xml","application/pdf"])
        ///download response not jsondecoder or propertylistdecoder, use raw data without decoded
        downloadRequest.response { (response)->Void in
            parseDownloadResponse(response: response, success: success, failure: failure)
        }
//        downloadRequest.responseDecodable(of:Empty.self) { (response) -> Void in
//            parseDownloadResponse(response: response, success: success, failure: failure)
//        }
        downloadRequest.onURLSessionTaskCreation { URLSessionTask in
            constructor(URLSessionTask)
        }
    }
    // MARK: - Monitor Methods
    /**
    objc public  func to setup a download connection.
    - Parameter  listener:reachabiity status notify listener
    */
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
    private class func parseResponse(response: AFDataResponse<Empty>, success: (_ response: HTTPURLResponse?, _ json: Any?) -> (),
                                     failure: (_ response: HTTPURLResponse?, _ error: NSError?) -> ()) {
            switch (response.result) {
            case .success:
                if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed) {
                    success(response.response, json)
                } else {
                    success(response.response, nil)
                }
            case .failure:
                failure(response.response, response.error as NSError?)
            }
    }
    ///json parse download response
    private class func parseDownloadResponse(response: AFDownloadResponse<URL?>, success: (_ response: HTTPURLResponse?, _ json: Any?) -> (),
                                     failure: (_ response: HTTPURLResponse?, _ error: NSError?) -> ()) {
            switch (response.result) {
            case .success:
                success(response.response, nil)
            case .failure:
                failure(response.response, response.error as NSError?)
            }
    }

}
