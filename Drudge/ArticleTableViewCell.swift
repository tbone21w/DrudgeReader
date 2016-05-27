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
  
  var delegate: CellGestureDelegate?
  
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

protocol CellGestureDelegate {
  func tableViewCellSubViewTapped(cell:UITableViewCell)
}
