//
//  PhotoService.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/25/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

enum ImageResult {
  case Success(UIImage)
  case Failure(ErrorType)
}

enum ImageError: ErrorType {
  case ImageCreationError
}


class ImageService {
  
  var coreDataStack:CoreDataStack!
  var imageStore:ImageStore!
  
  let session: NSURLSession = {
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    return NSURLSession(configuration: config)
  }()
  
  
  func fetchImage(article: Article, completion: (ImageResult) -> Void) {
    
    let url = NSURL(string: article.imageURL!)!
    let request = NSURLRequest(URL: url)
    
    if let key = article.imageID {
      if let image = imageStore.imageForKey(key) {
        completion(.Success(image))
        return
      }
    }
    
    
    
    //fetch image
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    let task = defaultSession.dataTaskWithRequest(request) {
      (data, response, error) -> Void in
      
      let result = self.processImageRequest(data: data, error: error)
      
            if case let .Success(image) = result {
              let imageKey = NSUUID().UUIDString
              article.imageID = imageKey
              self.coreDataStack.backgroundSave = true
              
              print("New Image Found, flagging core data for background save.  Image Key: \(imageKey)")
              
              //save image & entity
              self.imageStore.setImage(image, forKey: imageKey)
              
            }
      
      completion(result)
    }
    
    task.resume()
  }
  
  
  private func processImageRequest(data data: NSData?, error: NSError?) -> ImageResult {
    
    guard let
      imageData = data,
      image = UIImage(data: imageData) else {
        
        // Couldn't create an image
        if data == nil {
          return .Failure(error!)
        }
        else {
          return .Failure(ImageError.ImageCreationError)
        }
    }
    
    return .Success(image)
  }

  
}
