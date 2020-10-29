//
//  HeaderView.swift
//  SlidesMagic
//
//  Created by MareCrisium on 29/10/2020.
//  Copyright © 2020 razeware. All rights reserved.
//

import Cocoa

class HeaderView: NSView {
  
  @IBOutlet weak var sectionTitle: NSTextField!
  @IBOutlet weak var imageCount: NSTextField!
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    // Drawing code here.
    NSColor(calibratedWhite: 0.8, alpha: 0.8).set()
    dirtyRect.fill()
//    NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceOver)
  }
    
}
