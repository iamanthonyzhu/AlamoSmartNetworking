//
//  MultipartData.swift
//  AlamoSmartNetworking
//
//  Created by anthony zhu on 2023/8/8.
//

import Foundation
import Alamofire

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
