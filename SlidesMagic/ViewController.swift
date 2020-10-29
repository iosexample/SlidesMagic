/*
* ViewController.swift
* SlidesMagic
*
* Created by Gabriel Miro on Oct 2016.
* Copyright (c) 2016 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Cocoa

class ViewController: NSViewController {
  
  @IBOutlet weak var collectionView: NSCollectionView!
  @IBOutlet weak var addSlideButton: NSButton!
  @IBOutlet weak var removeSlideButton: NSButton!
  
  let imageDirectoryLoader = ImageDirectoryLoader()
  var indexPathsOfItemsBeingDragged: Set<IndexPath>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let initialFolderUrl = URL(fileURLWithPath: "/Library/Desktop Pictures", isDirectory: true)
    imageDirectoryLoader.loadDataForFolderWithUrl(initialFolderUrl)
    configureCollectionView()
    registerForDragAndDrop()
  }
  
  func loadDataForNewFolderWithUrl(_ folderURL: URL) {
    imageDirectoryLoader.loadDataForFolderWithUrl(folderURL)
    collectionView.reloadData()
  }

  fileprivate func configureCollectionView() {
    // 1
    let flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
    flowLayout.sectionInset = NSEdgeInsets(top: 30.0, left: 20.0, bottom: 30.0, right: 20.0)
    flowLayout.minimumInteritemSpacing = 20.0
    flowLayout.minimumLineSpacing = 20.0
    flowLayout.sectionHeadersPinToVisibleBounds = true
    collectionView.collectionViewLayout = flowLayout
    collectionView.wantsLayer = true
    collectionView.layer?.backgroundColor = NSColor.black.cgColor
  }
  
  @IBAction func showHideSections(_ sender: NSButton) {
    let show = sender.state
    imageDirectoryLoader.singleSectionMode = (show == .off)
    // The nil value passed means you skip image loading — same images, different layout.
    imageDirectoryLoader.setupDataForUrls(nil)
    collectionView.reloadData()
  }
  
  func updateItems(state:  NSCollectionViewItem.HighlightState, atIndexPaths: Set<IndexPath>) {
    for indexPath in atIndexPaths {
      guard let item = collectionView.item(at: indexPath) as? CollectionViewItem else { continue }
      item.highlightState = state
    }
    
    addSlideButton.isEnabled = collectionView.selectionIndexPaths.count == 1
    removeSlideButton.isEnabled = !collectionView.selectionIndexPaths.isEmpty
  }
  
  private func insertAtIndexPathFromURLs(urls: [URL], atIndexPath: IndexPath) {
    var indexPaths: Set<IndexPath> = []
    let section = atIndexPath.section
    var currentItem = atIndexPath.item
    
    for url in urls {
      guard let imageFile = ImageFile(url: url) else { continue }
      let currentIndexPath = IndexPath(item: currentItem, section: section)
      imageDirectoryLoader.insertImage(image: imageFile, atIndexPath: currentIndexPath)
      indexPaths.insert(currentIndexPath)
      currentItem += 1
    }
    
    collectionView.insertItems(at: indexPaths)
  }
  
  @IBAction func addSlide(sender: NSButton) {
    let insertAtIndexPath = collectionView.selectionIndexPaths.first!
    let openPanel = NSOpenPanel()
    openPanel.canChooseDirectories = false
    openPanel.canChooseFiles = true
    openPanel.allowsMultipleSelection = true;
    openPanel.allowedFileTypes = ["public.image"]
    openPanel.beginSheetModal(for: self.view.window!) { (response) -> Void in
      guard response == NSApplication.ModalResponse.OK else { return }
      self.insertAtIndexPathFromURLs(urls: openPanel.urls, atIndexPath: insertAtIndexPath)
    }
  }
  
  @IBAction func removeSlide(sender: NSButton) {
    
    let selectionIndexPaths = collectionView.selectionIndexPaths
    if selectionIndexPaths.isEmpty {
      return
    }
    
    var selectionArray = Array(selectionIndexPaths)
    selectionArray.sort { (path1, path2) -> Bool in
      path1.compare(path2) == .orderedDescending
    }
    
    for itemIndexPath in selectionArray {
      _ = imageDirectoryLoader.removeImageAtIndexPath(indexPath: itemIndexPath)
    }
    
    collectionView.animator().deleteItems(at: selectionIndexPaths)
  }
  
  func registerForDragAndDrop() {
    collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.URL])
    collectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
    collectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
  }
}

extension ViewController : NSCollectionViewDataSource {
  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    return imageDirectoryLoader.numberOfSections
  }
  
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageDirectoryLoader.numberOfItemsInSection(section)
  }
  
  func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    
    let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath)
    guard let collectionViewItem = item as? CollectionViewItem else {return item}
    
    let imageFile = imageDirectoryLoader.imageFileForIndexPath(indexPath)
    collectionViewItem.imageFile = imageFile
    
    if let selectedIndexPath = collectionView.selectionIndexPaths.first, selectedIndexPath == indexPath {
      collectionViewItem.highlightState = .forSelection
    } else {
      collectionViewItem.highlightState = .forDeselection
    }
    
    return item
  }
  
  func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
    if kind == NSCollectionView.elementKindSectionHeader {
      let identifier: String = kind == NSCollectionView.elementKindSectionHeader ? "HeaderView" : ""
      let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), for: indexPath) as! HeaderView
      view.sectionTitle.stringValue = "Section \(indexPath.section)"
      let numberOfItemsInSection = imageDirectoryLoader.numberOfItemsInSection(indexPath.section)
      view.imageCount.stringValue = "\(numberOfItemsInSection) image files"
      return view
    }
    else {
      // FIXME: Can't see the aqua vertical line unless commented out this method
      return NSView()
    }
  }
}

extension ViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
    return imageDirectoryLoader.singleSectionMode ? NSZeroSize : NSSize(width: 1000, height: 40)
  }
}

extension ViewController: NSCollectionViewDelegate {
  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    
    updateItems(state: .forSelection,
                   atIndexPaths: indexPaths)
  }
  
  func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    updateItems(state: .forDeselection, atIndexPaths: indexPaths)
  }
  
  func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
    return true
  }
  
  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
    let imageFile = imageDirectoryLoader.imageFileForIndexPath(indexPath)
    return imageFile.url.absoluteURL as? NSURL
  }
  
  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
    indexPathsOfItemsBeingDragged = indexPaths
  }
  
  func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
    if proposedDropOperation.pointee == NSCollectionView.DropOperation.on {
      proposedDropOperation.pointee = NSCollectionView.DropOperation.before
    }
    
    if indexPathsOfItemsBeingDragged == nil {
      return NSDragOperation.copy
    } else {
      return NSDragOperation.move
//      let sectionOfItemBeingDragged = indexPathsOfItemsBeingDragged.first!.section
//      let proposedDropsection = proposedDropIndexPath.pointee.section
//      if sectionOfItemBeingDragged == proposedDropsection && indexPathsOfItemsBeingDragged.count == 1 {
//        return NSDragOperation.move
//      } else {
//        return NSDragOperation(rawValue: 0)
//      }
    }
  }
  
  func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
    if indexPathsOfItemsBeingDragged != nil {
      let indexPathOfFirstItemBeingDragged = indexPathsOfItemsBeingDragged.first!
      var toIndexPath: IndexPath
      if indexPathOfFirstItemBeingDragged.compare(indexPath) == .orderedAscending {
        toIndexPath = IndexPath(item: indexPath.item-1, section: indexPath.section)
      } else {
        toIndexPath = IndexPath(item: indexPath.item, section: indexPath.section)
      }
      
      imageDirectoryLoader.moveImageFromIndexPath(indexPath: indexPathOfFirstItemBeingDragged, toIndexPath: toIndexPath)
      collectionView.moveItem(at: indexPathOfFirstItemBeingDragged, to: toIndexPath)
    } else {
      var droppedObjects = Array<URL>()
      draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: collectionView, classes: [NSURL.self], searchOptions: [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly : NSNumber(value: true)]) { (draggingItem, idx, stop) in
        if let url = draggingItem.item as? URL {
          droppedObjects.append(url)
        }
      }
      insertAtIndexPathFromURLs(urls: droppedObjects, atIndexPath: indexPath)
    }
    return true
  }
  
  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
    indexPathsOfItemsBeingDragged = nil
  }
}
