//
//  ArticleTableViewCell.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/15/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

class ArticleTableViewCell: UITableViewCell {
  
  
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var urlSnippet: UILabel!
  @IBOutlet weak var articleImage: UIImageView!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  @IBOutlet weak var articleImageWidthConstraint: NSLayoutConstraint!
  
  
  
  func updateWithImage(image: UIImage?) {
    if let imageToShow = image {
      spinner.stopAnimating()
      articleImage.image = imageToShow
      articleImageWidthConstraint.constant = articleImage.frame.height
    } else {
      spinner.hidden = true
      //spinner.startAnimating()
      //articleImage.image = nil
      //articleImage.hidden = true
      //
      
      articleImageWidthConstraint.constant = 0
    }
  }
  
  func updateWithArticle(article: Article) {
   
  }
  
  // MARK: Overrides
  override func awakeFromNib() {
    super.awakeFromNib()
    
    updateWithImage(nil)
  }
  
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    updateWithImage(nil)
  }
}
