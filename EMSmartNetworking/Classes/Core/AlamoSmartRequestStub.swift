//
//  AlamoSmartRequestStub.swift
//  NFZMSmartNetworking-iOS
//
//  Created by anthony zhu on 2023/4/26.
//

import Foundation
import Alamofire

func onMainAsync(execute work: @escaping @convention(block) () -> Void) {
    if Thread.isMainThread {
        work()
    } else {
        DispatchQueue.main.async(execute: work)
    }
}

func onMainAsyncSuccess(execute success: AlamoSmartSuccessCallback?) -> AlamoSmartSuccessCallback{
    return { (task:URLSessionTask?, response:AnyObject?) in
        if let block = success {
            onMainAsync {
                block(task,response)
            }
        }
    }
}

func onMainAsyncFailure(execute failure: AlamoSmartFailureCallback?) -> AlamoSmartFailureCallback{
    return { (task:URLSessionTask?, error:Error?, response:AnyObject?) in
        if let block = failure {
            onMainAsync {
                block(task,error,response)
            }
        }
    }
}



public class AlamoSmartRequestStub {
    
    private var apiName : String = ""
    
    private weak var task : URLSessionTask? = nil
    
    private weak var request : Request? = nil
    
    private var config : AlamoSmartConfigurationProtocol
    
    private var preTask : URLSessionTask? = nil
    
    private var beginTime : TimeInterval = 0.0
    
    private var endTime : TimeInterval = 0.0
    
    private var retryCount : Int = 3
    
    
    private var holder : AnyObject?
    
    public var envelopeCls : AnyClass?
    public var modelCls : AnyClass?
    public var dataClas : AnyClass?
    
    public var timeOutInterval : TimeInterval = 60.0 {
        didSet {
            self.resetOverTimer()
        }
    }
    private var timer : Timer? = nil
    
    private var success : AlamoSmartSuccessCallback? = nil
    
    private var failure : AlamoSmartFailureCallback? = nil
    
    private var constructor : AlamoSmartStubConstructor
    
//    deinit {
//        print("stub dealloc")
//    }
    
    init(apiName: String, task: URLSessionTask? = nil, request: Request? = nil, config: AlamoSmartConfigurationProtocol, preTask: URLSessionTask? = nil, holder: AnyObject? = nil, envelopeCls: AnyClass? = nil, modelCls: AnyClass? = nil, dataClas: AnyClass? = nil, timeOutInterval: TimeInterval? = 60.0, success: AlamoSmartSuccessCallback? = nil, failure: AlamoSmartFailureCallback? = nil, constructor: @escaping AlamoSmartStubConstructor) {
        self.apiName = apiName
        self.task = task
        self.request = request
        self.config = config
        self.preTask = preTask
        self.holder = holder
        self.envelopeCls = envelopeCls
        self.modelCls = modelCls
        self.dataClas = dataClas
        self.success = success
        self.failure = failure
        self.constructor = constructor
        
    }
    
    private func runContext() {
        let requestSync : AlamoSmartRequestSyncConstructor = {[weak self] (alRequest) in
            self?.holdBy(holder: alRequest,key:&AssociatedKeys.alamoRequest)
            self?.request = alRequest
        }
        
        let taskAsync : AlamoSmartTaskAsyncConstructor = { [weak self] (task) in
            self?.holdBy(holder: task,key:&AssociatedKeys.alamoRequest)
            self?.task = task
        }
        
        let completeHandler : AlamoSmartCompleteHanlder = { [weak self] (response, responseObject, error) in
            self?.endTime = Date().timeIntervalSince1970;
            // 解析原始responseData
            self?.config.alamoSmartNetworkLogInfo(log:"\n===AlamoSmartNetworking sessionTask===\n<<<URLString: \(response?.url?.absoluteString ?? "")\n<<<StatusCode: \(String(describing: response?.statusCode))\n<<<ResponseObject: \(String(describing: responseObject))\n<<<Duration: \((self?.endTime ?? 0.0) - (self?.beginTime ?? 0.0))s")
            
            let serializedRespObject = self?.config.alamoSmartEnvelopeDeserializer(envelopeClass: self?.envelopeCls, modelClass: self?.modelCls, dataClass: self?.dataClas, jsonObject: responseObject)
            
            let isSuspendOrCanceling:Bool = (self?.task?.state == URLSessionTask.State.suspended || self?.task?.state == URLSessionTask.State.canceling)
            var condition = false
            if let retry = self?.config.alamoSmartRetryConditioner(task: self?.task, response: response, responseObject: serializedRespObject, error: error) {
                condition = isSuspendOrCanceling && retry
            } else {
                condition = isSuspendOrCanceling
            }
            if condition {
//                print("\n===EMSmartNetworking sessionTask===\n \(self?.task?.currentRequest?.url) retry");
                self?.preTask = self?.task
                //self?.constructor(requestSync,taskAsync,self?.completeHandler)
                self?.retry()
                self?.resetOverTimer()

            } else {
                self?.config.alamoSmartCompletionIntercepter(task: self?.task, response: response, responseObject: serializedRespObject, error: error, success: onMainAsyncSuccess(execute:self?.success), failure: onMainAsyncFailure(execute:self?.failure))
                self?.timer?.invalidate()
                self?.withdrawForHolder(key: &AssociatedKeys.alamoRequest)

            }

        }

        constructor(requestSync,taskAsync,completeHandler)
    }
}

// MARK : 任务处理
extension AlamoSmartRequestStub {
    public func start() {
        beginTime = Date().timeIntervalSince1970
        self.runContext()
    }
    
    public func retry() {
        self.runContext()
    }

    public func cancel() {
        guard let request = self.request else {
            return
        }
        request.cancel()
    }
}

// MARK : - 定时器处理
extension AlamoSmartRequestStub {
    
    func createOverTimer() {
        Timer.scheduledTimer(withTimeInterval: timeOutInterval, repeats: false) { [weak self] (timer) in
            self?.timer = timer
            self?.cancel()
        }
     }
    
    func resetOverTimer() {
        if  let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        self.createOverTimer()
    }
    
}

// MARK : - 持有者变更
extension AlamoSmartRequestStub {
    struct AssociatedKeys {
        static var alamoRequest = "alamoRequest"
    }
    
    func holdBy(holder:AnyObject?,key:inout String) {
        guard let newHolder = holder else {
            return
        }
        if self.holder === holder {
            return ;
        }
        objc_setAssociatedObject(newHolder, &key, self, .OBJC_ASSOCIATION_RETAIN);
        if let oldHolder = self.holder {
            objc_setAssociatedObject(oldHolder, &key, nil, .OBJC_ASSOCIATION_RETAIN);
        }
        self.holder = newHolder
    }
    
    func withdrawForHolder(key:inout String) {
        guard let holder = self.holder else {
            return
        }
        objc_setAssociatedObject(holder, &key, nil, .OBJC_ASSOCIATION_RETAIN);
        self.holder = nil
    }

}

