//
//  CustomHTTPProtocol.swift
//  AgendaDottori
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

public class CustomHTTPProtocol: URLProtocol {
    static var blacklistedHosts = [String]()

    struct Constants {
        static let RequestHandledKey = "URLProtocolRequestHandled"
    }
    
    var session: URLSession?
    var sessionTask: URLSessionDataTask?
    var currentRequest: RequestModel?
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        }
    }
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard CustomHTTPProtocol.shouldHandleRequest(request) else { return false }

        if CustomHTTPProtocol.property(forKey: Constants.RequestHandledKey, in: request) != nil {
            return false
        }
        return true
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override public func startLoading() {
        let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        CustomHTTPProtocol.setProperty(true, forKey: Constants.RequestHandledKey, in: newRequest)
        sessionTask = session?.dataTask(with: newRequest as URLRequest)
        
        currentRequest = RequestModel(request: newRequest)
        Storage.shared.saveRequest(request: currentRequest)
    }
    
    override public func stopLoading() {
        currentRequest?.httpBody = body(from: request)
        if let startDate = currentRequest?.date{
            currentRequest?.duration = fabs(startDate.timeIntervalSinceNow) * 1000 //Find elapsed time and convert to milliseconds
        }

        Storage.shared.saveRequest(request: currentRequest)
    }
    
    private func body(from request: URLRequest) -> Data? {
        return request.httpBody ?? request.httpBodyStream.flatMap { stream in
            let data = NSMutableData()
            stream.open()
            while stream.hasBytesAvailable {
                var buffer = [UInt8](repeating: 0, count: 1024)
                let length = stream.read(&buffer, maxLength: buffer.count)
                data.append(buffer, length: length)
            }
            stream.close()
            return data as Data
        }
    }

    /// Inspects the request to see if the host has not been blacklisted and can be handled by this URL protocol.
    /// - Parameter request: The request being processed.
    private class func shouldHandleRequest(_ request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }

        return CustomHTTPProtocol.blacklistedHosts.filter({ host.hasSuffix($0) }).isEmpty
    }
    
    deinit {
        session = nil
        sessionTask = nil
        currentRequest = nil
    }
}

extension CustomHTTPProtocol {
    public func urlSession(didReceive data: Data) {
        if currentRequest?.dataResponse == nil{
            currentRequest?.dataResponse = data
        }
        else{
            currentRequest?.dataResponse?.append(data)
        }
    }
    
    public func urlSession(didReceive response: URLResponse) {
        currentRequest?.initResponse(response: response)
    }
    
    public func urlSession(didCompleteWithError error: Error?) {
        if let error = error {
            currentRequest?.errorClientDescription = error.localizedDescription
        }
    }
    
    public func urlSession(didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        currentRequest?.errorClientDescription = error.localizedDescription
    }
}

