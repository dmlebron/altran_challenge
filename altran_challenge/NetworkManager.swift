//
//  NetworkManager.swift
//  altran_challenge
//
//  Created by Dava on 7/7/17.
//
//

import UIKit

/// alias NSDictionary to JSON
public typealias JSON = NSDictionary

public typealias JSONArray = [NSDictionary]

/// Response
public typealias Response = (JSONArray?, NetworkError?) -> ()


/// Network Errors
public enum NetworkError: Error {
    case responseError(String)
    case connectionError(String)
}

class NetworkManager {
    
    // MARK: Properties
    let cache: NSCache<AnyObject, AnyObject>
    
    static let shared: NetworkManager = {
        let singleton = NetworkManager()
        return singleton
    }()
    
    init() {
        self.cache = NSCache()
    }
    
    // MARK: - Class Method
    
    /// Performs an HTTP GET
    ///
    /// - Parameters:
    ///   - url: url to send GET request
    ///   - completion: Response object
    static func get(url: URL, withCompletion completion: @escaping Response) {
        
        let request = URLRequest(url: url)
        
        let config = URLSessionConfiguration.default
        
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            
            if let error = error {
                return completion(nil, NetworkError.connectionError(error.localizedDescription))
            }
            
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON else {
                return completion(nil, NetworkError.responseError("Response Error"))
            }
            
            DispatchQueue.main.async {
                completion(json?["Brastlewark"] as? JSONArray, nil)
            }
        });
        
        task.resume()
    }
    
    // MARK: - instance Method
    
    /// Loads image from given url. Verifies if there exist an image for the url, if not, downloads the image and cache it.
    ///
    /// - Parameters:
    ///   - imageUrl: image url to download the image
    ///   - completion: cache image (or newly downloaded image), error
    func loadImage(from imageUrl: URL, with completion:@escaping (UIImage?, NetworkError?) -> Void) {
        URLSession.shared.downloadTask(with: imageUrl) { (url, response, error) in
            
            // returns if image already exists
            if let cacheImage = self.cacheImage(for: imageUrl.absoluteString as AnyObject) {
                DispatchQueue.main.async {
                    return completion(cacheImage, nil)
                }
            }
            
            guard let url = url, error == nil else {
                completion(nil, NetworkError.responseError(error!.localizedDescription))
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                
                guard let image = UIImage(data: data) else {
                    return completion(nil, NetworkError.responseError("Image Data Corrupted"))
                }
                
                // cache object
                self.cache.setObject(image, forKey: imageUrl.absoluteString as AnyObject)
                
                DispatchQueue.main.async {
                    return completion(image, nil)
                }
                
            } catch {
                completion(nil, NetworkError.responseError(error.localizedDescription))
            }
            
            }.resume()
    }
    
    /// Lookup if an image exist for the given key
    ///
    /// - Parameter key: key for the cache image
    /// - Returns: Cached image
    func cacheImage(for key: AnyObject) -> UIImage? {
        return self.cache.object(forKey: key) as? UIImage
    }
}









