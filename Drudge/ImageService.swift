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
  
  let session: NSURLSession = {
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    return NSURLSession(configuration: config)
  }()

  func fetchImage(imageURL: NSURL, completion: (ImageResult) -> Void) {
    let request = NSURLRequest(URL: imageURL)
    
    let task = session.dataTaskWithRequest(request) {
      (data, response, error) -> Void in
      
      let result = self.processImageRequest(data: data, error: error)
      
//      if case let .Success(image) = result {
//        photo.image = image
//        self.imageStore.setImage(image, forKey: photoKey)
//      }
      
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
