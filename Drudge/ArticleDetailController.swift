//
//  ArticleDetailController.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/17/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

class ArticleDetailController: UIViewController, UIWebViewDelegate {
  
  var article:Article!
  
  @IBOutlet weak var webView: UIWebView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var noResultsView: UIView!
  
  @IBAction func reloadPage(sender: AnyObject) {
    loadPage()
  }
  
  override func viewDidLoad() {
     super.viewDidLoad()
    
    noResultsView.hidden = true
    webView.delegate = self
    
    loadPage()

  }
  
  func loadPage() {
    let url:NSURL!
    
    if let href = article.href {
      url = NSURL(string: href)
    } else {
      url = NSURL(string: "http://google.com")
    }
    
    
    let request = NSURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 20 )
    webView.loadRequest(request)
  }
  
  
  func webViewDidStartLoad(webView: UIWebView) {

    activityIndicator.hidden = false
    activityIndicator.startAnimating()
  }
  
  func webViewDidFinishLoad(webView: UIWebView) {
    activityIndicator.hidden = true
    activityIndicator.stopAnimating()
  }
  
  func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
    noResultsView.hidden = false
    activityIndicator.hidden = true
    activityIndicator.stopAnimating()
  }
  
}
