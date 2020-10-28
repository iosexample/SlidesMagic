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
    }
    
}
