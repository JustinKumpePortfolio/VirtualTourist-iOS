//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/19/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import Foundation
import UIKit
import Alamofire_SwiftyJSON
import Alamofire

class FlickrClient {
    
//    MARK: Flickr API Key
    static let apiKey = "2284b32cd87842ea850b4450d93fa209"
    
//    MARK: Enum to build URL
    enum Endpoints {
        static var perPage = "25"
        static let baseUrl = "https://www.flickr.com/services/rest/"
        static let baseUrlWithBaseParams = "\(FlickrClient.Endpoints.baseUrl)?api_key=\(FlickrClient.apiKey)&per_page=\(FlickrClient.Endpoints.perPage)"
        
        case search(Double, Double, Int)
        case download(Int, String, String, String)
        
        var stringValue: String{
            switch self {
            case .search(let lat, let long, let page):
                return "\(Endpoints.baseUrlWithBaseParams)&method=flickr.photos.search&lat=\(lat)&lon=\(long)&page=\(page)&format=json&nojsoncallback=1"
            case .download(let farmId, let serverId, let id, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
        
//        MARK: Output Flickr Client URL
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
//    MARK: Search Photos
    class func searchPhotos(lat: Double, long: Double, page: Int, completion: @escaping (FlickrPhotosResponse?, Error?) -> Void){
        let url = Endpoints.search(lat, long, page).url
        
        taskForGet(url: url, responseType: FlickrPhotosResponse.self) {
            (response, error) in
            completion(response, error)
        }
    }
    
//    MARK: Task For Get
    class func taskForGet<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void){
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default) .responseSwiftyJSON { dataResponse in
                    
//            GUARD: isSuccess
            guard case dataResponse.result.isSuccess = true else {
                completion(nil,dataResponse.error)
                return
            }
                             
//            GUARD: Response
            guard let data = dataResponse.data else{
                completion(nil,dataResponse.error)
                return
            }
                    
                    
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(responseType.self, from: data)
                completion(response,nil)
            } catch let error {
                Logger.log(.error, "Task For Get: \(error.localizedDescription)")
                completion(nil,error)
            }
                    
                    
        }
    }
    
//    MARK: Download Image
    class func downloadImage(url: URL, index: Int, completionHandler: @escaping (UIImage?, Error?, Int) -> Void){
        Alamofire.request(url)
            .response {
                dataResponse in
                
                guard let data = dataResponse.data else{
                    Logger.log(.error, "downloadImage Error \(String(describing: dataResponse.error?.localizedDescription))")
                    completionHandler(nil,dataResponse.error,index)
                    return
                }
                let image = UIImage(data: data)
                completionHandler(image,nil,index)
        }
    }
    
    
}
