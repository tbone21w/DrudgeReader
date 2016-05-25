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
//    //// General Declarations
//    let context = UIGraphicsGetCurrentContext()
//    
//    //// Color Declarations
//    let color = UIColor(red: 0.314, green: 0.427, blue: 0.529, alpha: 1.000)
//    
//    //// Rectangle Drawing
//    let rectanglePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 91, height: 27), cornerRadius: 8)
//    color.setFill()
//    rectanglePath.fill()
//    
//    
//    //// Text Drawing
//    let textRect = CGRect(x: 10, y: 3, width: 71, height: 21)
//    let textTextContent = NSString(string: "Updates")
//    let textStyle = NSMutableParagraphStyle()
//    textStyle.alignment = .Left
//    
//    let textFontAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(UIFont.labelFontSize()), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: textStyle]
//    
//    let textTextHeight: CGFloat = textTextContent.boundingRectWithSize(CGSize(width: textRect.width, height: CGFloat.infinity), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: textFontAttributes, context: nil).size.height
//    CGContextSaveGState(context)
//    CGContextClipToRect(context, textRect)
//    textTextContent.drawInRect(CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight), withAttributes: textFontAttributes)
//    CGContextRestoreGState(context)
  }
}
