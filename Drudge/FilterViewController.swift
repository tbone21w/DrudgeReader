//
//  FilterViewController.swift
//  Drudge
//
//  Created by Todd Isaacs on 6/1/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit

class FilterViewController: UITableViewController {
  
  
  @IBOutlet weak var allContentCell: UITableViewCell!

  @IBOutlet weak var unreadContentCell: UITableViewCell!
  
  @IBOutlet weak var readContentCell: UITableViewCell!
  
  
  
  @IBOutlet weak var headlineSectionCell: UITableViewCell!
  @IBOutlet weak var topStorySectionCell: UITableViewCell!
  
  @IBOutlet weak var columnSectionCell: UITableViewCell!
  
  @IBOutlet weak var sortUpdatedNewestCell: UITableViewCell!
  @IBOutlet weak var sortUpdatedOldestCell: UITableViewCell!
  
  @IBOutlet weak var sortCreatedNewestCell: UITableViewCell!
  @IBOutlet weak var sortCreatedOldestCell: UITableViewCell!
  
  
  
}
