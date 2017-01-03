
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
    var session: NSURLSession {
        return NSURLSession.sharedSession()
    }
    
    func urlRequestWithPath(path: String, method: APIMethod? = .Get, params: [String: AnyObject], body: AnyObject? = nil) -> NSMutableURLRequest {
        let components = NSURLComponents()
        components.queryItems = params.map { NSURLQueryItem(name: $0, value: String($1)) }
        let paramsString = components.percentEncodedQuery ?? ""
        
        let urlString = path + "?" + paramsString
        if let url = NSURL(string: urlString) {
            let req = NSMutableURLRequest(URL: url)
            req.HTTPMethod = (method?.rawValue)!
            for (header, value) in headers {
                req.addValue(value, forHTTPHeaderField: header)
            }
            if body != nil {
                do {
                    req.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(body!, options: [])
                }
            }
            return req
        } else {
            fatalError("no url found")
        }
    }
    
    func sendURLRequest(request: NSURLRequest, handler: (result: AnyObject?, error: String?) -> Void) {
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            guard error == nil else {
                handler(result: nil, error: "Connection error")
                return
            }
            
            guard let status = (response as? NSHTTPURLResponse)?.statusCode where status != 403 else {
                handler(result: nil, error: "Username or password is incorrect")
                return
            }
            
            if let data = data {
                let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String: AnyObject]
                handler(result: json, error: nil)
            } else {
                handler(result: nil, error: "Connection error with wrong data")
                return
            }            
        })
        
        task.resume()
    }
}
