//
//  DataFetcher.swift
//  Wormholy-Demo-iOS
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation
import Wormholy

class DataFetcher: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {

    var session : URLSession? //Session manager
    var httpProtocol: [Int: CustomHTTPProtocol] = [:]
    
    //MARK: Singleton
    static let sharedInstance = DataFetcher(managerCachePolicy: .reloadIgnoringLocalCacheData)
    
    //MARK: Init
    override init() {
        super.init()
    }
    
    init(managerCachePolicy:NSURLRequest.CachePolicy){
        super.init()
        self.configure(cachePolicy: managerCachePolicy)
    }
    
    //MARK: Session Configuration
    func configure(cachePolicy:NSURLRequest.CachePolicy?){
        let sessionConfiguration = URLSessionConfiguration.default //URLSessionConfiguration()
        sessionConfiguration.timeoutIntervalForRequest = 10.0
        sessionConfiguration.requestCachePolicy = cachePolicy != nil ? cachePolicy! : .reloadIgnoringLocalCacheData
        sessionConfiguration.httpAdditionalHeaders = ["Accept-Language": "en"]
        self.session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    
    //MARK: API Track
    func getPost(id: Int, completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.Post(id).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest)
        httpProtocol[task!.hashValue] = CustomHTTPProtocol(task: task!, cachedResponse: nil, client: nil)
        httpProtocol[task!.hashValue]?.startLoading()
        task?.resume()
    }
    
    func newPost(userId: Int, title: String, body: String, completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.NewPost(userId: userId, title: title, body: body).urlRequest
        urlRequest.httpMethod = "POST"
        
        let task = session?.dataTask(with: urlRequest)
        
        task?.resume()
    }
    
    func getWrongURL(completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.WrongURL(()).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest)
        
        task?.resume()
    }
    
    func getPhotosList(completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.Photos(()).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest)
        
        task?.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("RECEIVE")
        httpProtocol[dataTask.hashValue]?.urlSession(didReceive: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("ERROR")
        httpProtocol[task.hashValue]?.urlSession(didCompleteWithError: error)
        httpProtocol[task.hashValue]?.stopLoading()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        httpProtocol[dataTask.hashValue]?.urlSession(didReceive: response)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("CHALLENGE")
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender

        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                print("CHALLENGE")

    }
}

