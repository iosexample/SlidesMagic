//
//  CollectionViewItem.swift
//  SlidesMagic
//
//  Created by Don on 28/10/2020.
//  Copyright © 2020 razeware. All rights reserved.
//

import Cocoa

class CollectionViewItem: NSCollectionViewItem {

  // 1
  var imageFile: ImageFile? {
    didSet {
      guard isViewLoaded else { return }
      if let imageFile = imageFile {
        imageView?.image = imageFile.thumbnail
        textField?.stringValue = imageFile.fileName
      } else {
        imageView?.image = nil
        textField?.stringValue = ""
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    view.layer?.borderColor = NSColor.white.cgColor
    view.layer?.borderWidth = 0.0
  }
    
  override var isSelected: Bool {
    didSet {
      view.layer?.borderWidth = isSelected ? 4.0 : 0.0
    }
  }
}
