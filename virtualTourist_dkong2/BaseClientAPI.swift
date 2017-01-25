
//  BaseAPIClient.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 11/19/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation

enum APIMethod: String {
    case Get
    case Put
    case Post
    case Delete
}

class BaseClientAPI: NSObject {
    var headers: [String: String] = [String: String]()
    var session: URLSession {
        return URLSession.shared
    }
    
    func urlRequestWithPath(_ path: String, method: APIMethod? = .Get, params: [String: AnyObject], body: AnyObject? = nil) -> NSMutableURLRequest {
        var components = URLComponents()
        components.queryItems = params.map { URLQueryItem(name: $0, value: String(describing: $1)) }
        let paramsString = components.percentEncodedQuery ?? ""
        
        let urlString = path + "?" + paramsString
        if let url = URL(string: urlString) {
            let req = NSMutableURLRequest(url: url)
            req.httpMethod = (method?.rawValue)!
            for (header, value) in headers {
                req.addValue(value, forHTTPHeaderField: header)
            }
            if body != nil {
                do {
                    req.httpBody = try! JSONSerialization.data(withJSONObject: body!, options: [])
                }
            }
            return req
        } else {
            fatalError("no url found")
        }
    }
    
    func sendURLRequest(_ request: URLRequest, handler: @escaping (_ result: AnyObject?, _ error: String?) -> Void) {
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            guard error == nil else {
                var errorString = ""
                
                if error!._code < 400 && error!._code > 299 {
                    errorString = "HTTP Errors"
                } else if error!._code == -1001 {
                    errorString = "Connection timed out"
                } else if error!._code < 200 && error!._code >= 120 {
                    errorString = "SOCK Errors"
                }
                handler(nil, errorString)
                return
            }
            
            guard let status = (response as? HTTPURLResponse)?.statusCode, status != 403 else {
                handler(nil, "Username or password is incorrect")
                return
            }
            
            if let data = data {
                let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                handler(json as AnyObject?, nil)
            } else {
                handler(nil, "Connection error with wrong data")
                return
            }            
        })
        
        task.resume()
    }
}
