//
//  UpdateIndicator.swift
//  Drudge
//
//  Created by Todd Isaacs on 5/18/16.
//  Copyright © 2016 Todd Isaacs. All rights reserved.
//

import UIKit


class UpdateIndicator: UIView {
  
  override func drawRect(rect: CGRect) {    
    DrudgeStyleKit.drawUpdateButton()
  }
}
