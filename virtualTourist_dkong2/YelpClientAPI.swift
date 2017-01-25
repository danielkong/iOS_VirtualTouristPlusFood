//
//  YelpClientAPI.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/11/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation

enum YelpSortType: String {
    case BestMatched = "best_match"
    case Distance = "distance"
    case HighestRated = "rating"
    case MostReviewd = "review_count"
}

class YelpClientAPI: BaseClientAPI {
    
    struct YelpParamsKey {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let term = "term"
        static let limit = "limit"
        static let offset = "offset"
        static let sort_by = "sort_by"
        static let categories = "categories"
        static let radius = "radius"
    }
    
    fileprivate let yelpApiUrl = "https://api.yelp.com"
    fileprivate let apiUrl = "https://api.yelp.com/v3/businesses/search"
    var accessToken: String? = nil
    
    override init() {
        accessToken = nil
    }
    
    init(token: String) {
        accessToken = token
        super.init()
    }

    // OAuth
    func authRequestWithAppID(_ appId: String, secret: String) -> NSMutableURLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.yelp.com"
        urlComponents.path = "/oauth2/token"
        
        let body = String(format:"grant_type=client_credentials&client_id=\(appId)&client_secret=\(secret)")
        let bodyData = body.data(using: String.Encoding.utf8)
        
        let request = NSMutableURLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue(String(bodyData!.count), forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    func authWithAppID(_ appID: String, secret: String, completionHandler:@escaping (_ yclient: YelpClientAPI?, _ error: String?) -> Void) {
        let request = authRequestWithAppID(appID, secret: secret)
        sendURLRequest(request as URLRequest) { (result, error) -> Void in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            guard let token = result!["access_token"] as? String else {
                print("Not found [token] in response")
                return
            }
            
            let client = YelpClientAPI(token: token)
            completionHandler(client, nil)
        }
    }
    
    func searchWithLat(_ lat: Double, long: Double, term: String, limit: Int, offset:Int, sort: YelpSortType, completionHandler:@escaping (_ businesses: AnyObject?, _ error: String?) -> Void) {
        let params: [String: AnyObject] = [
            YelpParamsKey.Latitude: lat as AnyObject,
            YelpParamsKey.Longitude: long as AnyObject,
            YelpParamsKey.term: term as AnyObject,
            YelpParamsKey.limit: limit as AnyObject,
            YelpParamsKey.offset: offset as AnyObject,
            YelpParamsKey.sort_by: sort.rawValue as AnyObject,
            ]
        
        if let token = self.accessToken {
            self.headers = ["Authorization": "Bearer \(token)"]
        }
        let request: URLRequest = urlRequestWithPath("\(apiUrl)", params: params) as URLRequest
        sendURLRequest(request) { (result, error) -> Void in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            guard let businessData = result!["businesses"] as? [NSDictionary] else {
                print("Not found [businesses] in response")
                completionHandler(nil, "Wrong response")
                return
            }

            completionHandler(businessData as AnyObject?, nil)
        }


    }
}
