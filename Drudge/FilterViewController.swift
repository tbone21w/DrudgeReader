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
  
  @IBAction func cancel(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion:nil)
  }
  
  @IBAction func resetFilters(sender: AnyObject) {
    selectedSort = updatedAtNewest
    selectedPredicate = allPredicate
  
    setCheckmarks()
  }
  
  @IBAction func ApplyFilter(sender: AnyObject) {
    delegate!.filterViewController(self,
                                   didSelectPredicate: selectedPredicate,
                                   sortDescriptor: selectedSort)
    
    
    dismissViewControllerAnimated(true, completion:nil)
  }
  
  weak var delegate: FilterViewControllerDelegate?
  
  var selectedPredicate:NSPredicate?
  var selectedSort:NSSortDescriptor?
  
  //PREDICATES
  var allPredicate = NSPredicate(format: "'1' = '1'")
  var unreadPredicate = NSPredicate(format: "read == false")
  var readPredicate = NSPredicate(format: "read == true")
  
  //SORTS
  var updatedAtNewest =  NSSortDescriptor(key: "updatedAt", ascending: false)
  var updatedAtOldest =  NSSortDescriptor(key: "updatedAt", ascending: true)
  var createdAtNewest =  NSSortDescriptor(key: "createdAt", ascending: false)
  var createdAtOldest =  NSSortDescriptor(key: "createdAt", ascending: true)

  //COLUMN TOP_STORY MAIN_HEADLINE
  var columnPredicate = NSPredicate(format: "location == 'COLUMN'")
  var topStoryPredicate = NSPredicate(format: "location == 'TOP_STORY'")
  var mainHeadlinePredicate = NSPredicate(format: "location == 'MAIN_HEADLINE'")
  
  override func viewDidLoad() {
    setCheckmarks()
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    
    switch cell {
    case allContentCell:
      selectedPredicate = allPredicate
    case unreadContentCell:
      selectedPredicate = unreadPredicate
    case readContentCell:
      selectedPredicate = readPredicate
    case topStorySectionCell:
      selectedPredicate = topStoryPredicate
    case headlineSectionCell:
      selectedPredicate = mainHeadlinePredicate
    case columnSectionCell:
      selectedPredicate = columnPredicate
      
    case sortUpdatedOldestCell:
      selectedSort = updatedAtOldest
    case sortUpdatedNewestCell:
      selectedSort = updatedAtNewest
    case sortCreatedNewestCell:
      selectedSort = createdAtNewest
    case sortCreatedOldestCell:
      selectedSort = createdAtOldest
      
    default:
      selectedPredicate = allPredicate
      selectedSort = updatedAtNewest
    }
    
  
    setCheckmarks()
  }
  
  func setCheckmarks() {
    clearAllSearchPredicateCells()
    
    if let searchPredicate = selectedPredicate {
      
      switch searchPredicate.predicateFormat {
      case readPredicate.predicateFormat:
        readContentCell.accessoryType = .Checkmark
        
      case unreadPredicate.predicateFormat:
          unreadContentCell.accessoryType = .Checkmark
        
      case mainHeadlinePredicate.predicateFormat:
        headlineSectionCell.accessoryType = .Checkmark
        
      case topStoryPredicate.predicateFormat:
        topStorySectionCell.accessoryType = .Checkmark
        
      case columnPredicate.predicateFormat:
        columnSectionCell.accessoryType = .Checkmark
        
      default:
          allContentCell.accessoryType = .Checkmark
     }
      
      if let sort = selectedSort {
        switch sort.description {
        case updatedAtNewest.description:
          sortUpdatedNewestCell.accessoryType = .Checkmark
          
        case updatedAtOldest.description:
          sortUpdatedOldestCell.accessoryType = .Checkmark
          
        case createdAtNewest.description:
          sortCreatedNewestCell.accessoryType = .Checkmark
          
        case createdAtOldest.description:
          sortCreatedOldestCell.accessoryType = .Checkmark
          
        default:
          sortUpdatedNewestCell.accessoryType = .Checkmark
        }
        
      } else {
        sortUpdatedOldestCell.accessoryType = .Checkmark
      }
    }
    
  }
  
  func clearAllSearchPredicateCells() {
    allContentCell.accessoryType = .None
    readContentCell.accessoryType = .None
    unreadContentCell.accessoryType = .None
    headlineSectionCell.accessoryType = .None
    topStorySectionCell.accessoryType = .None
    columnSectionCell.accessoryType = .None
    sortUpdatedOldestCell.accessoryType = .None
    sortUpdatedNewestCell.accessoryType = .None
    sortCreatedNewestCell.accessoryType = .None
    sortCreatedOldestCell.accessoryType = .None
  }

  
}



protocol FilterViewControllerDelegate: class {
  func filterViewController(filter: FilterViewController,
                            didSelectPredicate predicate:NSPredicate?,
                                               sortDescriptor: NSSortDescriptor?)
}
