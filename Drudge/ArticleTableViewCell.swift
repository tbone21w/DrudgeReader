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
  
  @IBOutlet weak var timeAgoLabel: UILabel!
  @IBOutlet weak var articleImageWidthConstraint: NSLayoutConstraint!
  
  weak var delegate: CellGestureDelegate?
  
  //need to track the article since managed result controller may be different than table view
  weak var article:Article! {
    didSet {
      self.title.text = article.title
      
      if article.read == true {
        title.font = UIFont.systemFontOfSize(14.0)
        title.textColor = DrudgeStyleKit.readArticle
      } else {
        
        title.font = UIFont.boldSystemFontOfSize(16.0)
        title.textColor = DrudgeStyleKit.unreadArticle
      }
      
      let url = NSURL(string: article.href!)
      urlSnippet.text = url?.host
      urlSnippet.textColor = DrudgeStyleKit.unreadArticle
      
      timeAgoLabel.text = article.updatedAt?.timeAgoSimple
      timeAgoLabel.textColor = DrudgeStyleKit.unreadArticle
    }
  }
  
  func handleImageTap(recognizer:UIGestureRecognizer) {
    if recognizer.state == .Ended {
        delegate?.tableViewCellSubViewTapped(self)
    }
  }
  
  
  // MARK: Overrides
  override func awakeFromNib() {
    super.awakeFromNib()
    articleImage.image = nil
  }
  
  
  override func prepareForReuse() {
    super.prepareForReuse()
    articleImage.image = nil
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
    articleImage.userInteractionEnabled = true
    articleImage.addGestureRecognizer((tapGesture))
  }
  
}

protocol CellGestureDelegate: class {
  func tableViewCellSubViewTapped(cell:UITableViewCell)
}
