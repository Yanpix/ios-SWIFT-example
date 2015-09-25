//
//  DappLinksVC.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 9/21/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import UIKit

@objc protocol DappLinksVCDelegate {
  optional func addLink(link: Link, completion: (success: Bool, error: NSError?) -> Void)
  optional func deleteLinkAtIndex(linkIndex: Int, completion: (success: Bool, error: NSError?) -> Void)
  func getLinkAtIndex(index: Int) -> Link?
  func getLinksCount() -> Int
  func canDeleteLinks() -> Bool
  func getNextState(currentState: DappLinkCellState) -> DappLinkCellState
  func getStateForNoLink() -> DappLinkCellState
  optional func openURL(URL: NSURL) -> Void
  optional func openLinkOnTap() -> Bool
}

class DappLinksVC: UIViewController {
  @IBOutlet weak var dappLinksView: DappLinksView!
  
  internal var delegate: DappLinksVCDelegate?
  
  private let cellReuseID = "cell"
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let NIB = UINib(nibName: "DappLinkCell", bundle: nil)
    
    self.dappLinksView.linksTableView.registerNib(NIB, forCellReuseIdentifier: cellReuseID)
    
    self.dappLinksView.linksTableView.dataSource = self
    self.dappLinksView.linksTableView.delegate = self
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  private func getTitleFromURL(URL: NSURL, completion: (title: String?, errorMessage: String?) -> Void) {
    Requests.downloadDataFromURL(URL, completion: { (data: NSData?, error: NSError?) -> Void in
      if let data = data {
        if let parser = try? HTMLParser(data: data) {
          let headTag = parser.head() as HTMLNode?
          let titleTag = headTag?.findChildTag("title") as HTMLNode?
          let title = titleTag?.contents()
          
          completion(title: title, errorMessage: nil)
        } else {
          let errorMessage = "Parsing error. Failed to get the title from \(URL)."
          
          completion(title: nil, errorMessage: errorMessage)
        }
      } else if let error = error {
        completion(title: nil, errorMessage: error.localizedDescription)
      } else {
        completion(title: nil, errorMessage: nil)
      }
    })
  }
}

extension DappLinksVC: UITableViewDataSource {
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseID) as! DappLinkCell
    
    cell.delegate = self
    
    if let link = self.delegate?.getLinkAtIndex(indexPath.row) {
      cell.goToState(.Link)
      cell.showLinkInfo(linkIndex: indexPath.row + 1, linkTitle: link.title)
    } else if let state = self.delegate?.getStateForNoLink() {
      cell.goToState(state)
    } else {
      cell.goToState(.NoLink)
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }
}

extension DappLinksVC: UITableViewDelegate {
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! DappLinkCell
    
    if let newState = self.delegate?.getNextState(cell.state) {
      cell.goToState(newState)
    }
  }
}

extension DappLinksVC: DappLinkCellDelegate {
  func didEnterURLString(URLString: String, cell: DappLinkCell) {
    if let URL = NSURL(string: URLString) {
      cell.makeViews(ViewsState.Disabled)
      
      self.getTitleFromURL(URL, completion: { (title: String?, errorMessage: String?) -> Void in
        cell.makeViews(.Enabled)
        
        if let title = title {
          if let delegate = self.delegate {
            let link = Link(URLStr: URLString, title: title)
            
            delegate.addLink?(link, completion: {
              (success: Bool, error: NSError?) -> Void in
              if success {
                let linkIndexPath = NSIndexPath(forRow: delegate.getLinksCount() - 1, inSection: 0)
                
                if let linksTableView = self.dappLinksView.linksTableView {
                  linksTableView.reloadRowsAtIndexPaths([linkIndexPath]
                  , withRowAnimation: UITableViewRowAnimation.Automatic
                  )
                  
                  if let cellIndexPath = linksTableView.indexPathForCell(cell) {
                    linksTableView.reloadRowsAtIndexPaths([cellIndexPath]
                    , withRowAnimation: UITableViewRowAnimation.Automatic
                    )
                  }
                }
              } else {
                var errorStr = "Failed to add link with URL: \(link.URLStr) and title: \(link.title)."
                
                if let error = error {
                  errorStr += " Error: \(error)."
                } else {
                  errorStr += " Unknown error."
                }
                
                print(errorStr)
              }
            })
          } else {
            cell.goToState(DappLinkCellState.NoLink)
          }
        } else if let errorMessage = errorMessage {
          UIAlertView(
            title: nil
          , message: errorMessage
          , delegate: nil
          , cancelButtonTitle: "OK"
          ).show()
          
          cell.goToState(DappLinkCellState.NoLink)
        } else {
          cell.goToState(DappLinkCellState.NoLink)
        }
      })
    } else {
      UIAlertView(
        title: nil
      , message: "Incorrect URL."
      , delegate: nil
      , cancelButtonTitle: "OK"
      ).show()
    }
  }
  
  func deleteLinkInCell(cell: DappLinkCell) {
    if let indexPath = self.dappLinksView.linksTableView.indexPathForCell(cell) {
      self.delegate?.deleteLinkAtIndex?(indexPath.row, completion: {
        (success: Bool, error: NSError?) -> Void in
        if !success {
          var errorStr = "Failed to delete link at index \(indexPath.row)."
          
          if let error = error {
            errorStr += " Error: \(error)"
          } else {
            errorStr += " Unknown error."
          }
          
          print(errorStr)
        }
      })
    }
  }
  
  func openLinkInCell(cell: DappLinkCell) {
    if let 	indexPath = self.dappLinksView.linksTableView.indexPathForCell(cell)
      , link      = self.delegate?.getLinkAtIndex(indexPath.row)
      , URLStr    = link.URLStr
      , URL       = NSURL(string: URLStr) {
        self.delegate?.openURL?(URL)
    }
  }
  
  func openLinkOnTap() -> Bool {
    if let open = self.delegate?.openLinkOnTap?() {
      return open
    }
    
    return false
  }
}
