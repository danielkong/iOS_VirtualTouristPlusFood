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
    
    private let yelpApiUrl = "https://api.yelp.com"
    private let apiUrl = "https://api.yelp.com/v3/businesses/search"
    var accessToken: String? = nil
    
    override init() {
        accessToken = nil
    }
    
    init(token: String) {
        accessToken = token
        super.init()
    }

    // OAuth
    func authRequestWithAppID(appId: String, secret: String) -> NSMutableURLRequest {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.yelp.com"
        urlComponents.path = "/oauth2/token"
        
        let body = String(format:"grant_type=client_credentials&client_id=\(appId)&client_secret=\(secret)")
        let bodyData = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        let request = NSMutableURLRequest(URL: urlComponents.URL!)
        request.HTTPMethod = "POST"
        request.HTTPBody = bodyData
        request.setValue(String(bodyData!.length), forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    func authWithAppID(appID: String, secret: String, completionHandler:(yclient: YelpClientAPI?, error: String?) -> Void) {
        let request = authRequestWithAppID(appID, secret: secret)
        sendURLRequest(request) { (result, error) -> Void in
            guard error == nil else {
                completionHandler(yclient: nil, error: error)
                return
            }
            
            guard let token = result!["access_token"] as? String else {
                print("Not found [token] in response")
                return
            }
            
            let client = YelpClientAPI(token: token)
            completionHandler(yclient: client, error: nil)
        }
    }
    
    func searchWithLat(lat: Double, long: Double, term: String, limit: Int, offset:Int, sort: YelpSortType, completionHandler:(businesses: AnyObject?, error: String?) -> Void) {
        let params: [String: AnyObject] = [
            YelpParamsKey.Latitude: lat,
            YelpParamsKey.Longitude: long,
            YelpParamsKey.term: term,
            YelpParamsKey.limit: limit,
            YelpParamsKey.offset: offset,
            YelpParamsKey.sort_by: sort.rawValue,
            ]
        
        if let token = self.accessToken {
            self.headers = ["Authorization": "Bearer \(token)"]
        }
        let request: NSURLRequest = urlRequestWithPath("\(apiUrl)", params: params) as NSURLRequest
        sendURLRequest(request) { (result, error) -> Void in
            guard error == nil else {
                completionHandler(businesses: nil, error: error)
                return
            }
            
            guard let businessData = result!["businesses"] as? [NSDictionary] else {
                print("Not found [businesses] in response")
                completionHandler(businesses: nil, error: "Wrong response")
                return
            }

            completionHandler(businesses: businessData, error: nil)
        }


    }
}
