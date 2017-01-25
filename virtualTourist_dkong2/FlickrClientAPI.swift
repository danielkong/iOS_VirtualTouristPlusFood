//
//  FlickrClientAPI.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 11/21/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation

class FlickrClientAPI: BaseClientAPI {
    let apiUrl = "https://api.flickr.com/services/rest/"
    
    struct LocationConstants {
        static let Lat_Min = -90.0
        static let Lat_Max = 90.0
        static let Lon_Min = -180.0
        static let Lon_Max = 180.0
        
        static let Bounding_Box_Half_Width = 1.0
        static let Bounding_Box_Half_Height = 1.0
    }
    
    struct FlickrParamsValue {
        static let URL_M = "url_m"
        static let JSON = "json"
        static let MethodValue = "flickr.photos.search"
        static let ApiValue = "8c478e5a68b4cd1b92f53f31d039d831"

    }
    
    struct FlickrParamsKey {
        static let Method = "method"
        static let Api_Key = "api_key"
        static let Bbox = "bbox"
        static let Safe_Search = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Per_Page = "per_page"
        static let Page = "page"
    }
    
    static let shared = FlickrClientAPI()
    
    func BoundingBoxString(_ latitude: Double, longitude: Double) -> String {
        let bottom_left_lon = max(longitude - LocationConstants.Bounding_Box_Half_Width, LocationConstants.Lon_Min)
        let bottom_left_lat = max(latitude - LocationConstants.Bounding_Box_Half_Height, LocationConstants.Lat_Min)
        let top_right_lon = min(longitude + LocationConstants.Bounding_Box_Half_Height, LocationConstants.Lon_Max)
        let top_right_lat = min(latitude + LocationConstants.Bounding_Box_Half_Height, LocationConstants.Lat_Max)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func loadPhotosWithCoordinate(_ latitude: Double, longitude: Double, page: Int = 1, handler: @escaping (_ photos: [[String : AnyObject]]?, _ pages: Int, _ error: String?) -> Void) {
        
        let params = [
            FlickrParamsKey.Method: FlickrParamsValue.MethodValue,
            FlickrParamsKey.Api_Key: FlickrParamsValue.ApiValue,
            FlickrParamsKey.Bbox: BoundingBoxString(latitude, longitude: longitude),
            FlickrParamsKey.Safe_Search: "1",
            FlickrParamsKey.Extras: FlickrParamsValue.URL_M,
            FlickrParamsKey.Format: FlickrParamsValue.JSON,
            FlickrParamsKey.NoJSONCallback: "1",
            FlickrParamsKey.Per_Page: "30",
            FlickrParamsKey.Page: String(page),
        ]
        let request: URLRequest = urlRequestWithPath("\(apiUrl)", params: params as [String : AnyObject]) as URLRequest
        sendURLRequest(request) { (result, error) -> Void in
            guard error == nil else {
                handler(nil, 0, error)
                return
            }
            
            guard let photoData = result!["photos"] as? [String : AnyObject] else {
                print("Not found [photos] in response")
                handler(nil, 0, "Wrong response")
                return
            }
            
            guard let pages = photoData["pages"] as? Int else {
                print("Not found [photos][pages] in response")
                handler(nil, 0, "Wrong response")
                return
            }
            
            guard let results = photoData["photo"] as? [[String : AnyObject]] else {
                print("Not found [photos][photo] in response")
                handler(nil, 0, "Wrong response")
                return
            }
            
            handler(results, pages, nil)
        }
    }
}
