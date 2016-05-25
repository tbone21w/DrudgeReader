//
//  ArticleDetailController.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

class ArticleDetailController: UIViewController {
  
  var article:Article!
  
  @IBOutlet weak var webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let url:NSURL!
    
    if let href = article.href {
      url = NSURL(string: href)
    } else {
      url = NSURL(string: "http://google.com")
    }
    
    let request = NSURLRequest(URL: url)
    webView.loadRequest(request)
  }
}
