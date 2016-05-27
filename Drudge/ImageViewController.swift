//
//  ImageViewController.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/25/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  
  var image:UIImage!
  
  override func viewDidLoad() {
     imageView.image = image
  }
}
