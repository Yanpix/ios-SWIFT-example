//
//  PrimaryDapps.swift
//  DappSign
//
//  Created by Oleksiy Kovtun on 3/16/15.
//  Copyright (c) 2015 DappSign. All rights reserved.
//

import Foundation

internal let primaryDappsMaxCount = 200

class PrimaryDapps {
  class func sortDapps(dapps: [PFObject]) -> [PFObject] {
    var sortedDapps: [PFObject] = []
    
    // find dapps with correct indexes
    var dappsWithIndexes = dapps.filter({ (dapp: PFObject) -> Bool in
      if let index = dapp["index"] as? Int {
        if index >= 0 {
          return true
        }
        
        return false
      }
      
      return false
    })
    
    // sort by indexes from biggest to lowest
    dappsWithIndexes.sortInPlace({ (dapp1, dapp2) -> Bool in
      return dapp2["index"] as? Int > dapp1["index"] as? Int
    })
    
    // dapps without indexes or with incorrect indexes
    var dappsWithoutIndexes = dapps.filter({ (dapp: PFObject) -> Bool in
      if let index = dapp["index"] as? Int {
        if index < 0 {
          return true
        }
        
        return false
      }
      
      return true
    })
    
    var dappWithIndex = dappsWithIndexes.first
    
    // if there is a dapp with the same index as dappIndex, then it will be added to the
    // sortedDapps array, otherwise if there is a dapp without an index or with incorrect index,
    // it will be added to sortedDapps array
    for var dappIndex = 0; dappIndex < primaryDappsMaxCount; ++dappIndex {
      if dappWithIndex != nil {
        if let index = dappWithIndex!["index"] as? Int {
          if dappIndex == index {
            sortedDapps.append(dappWithIndex!)
            dappsWithIndexes.removeAtIndex(0)
            
            dappWithIndex = dappsWithIndexes.first
          } else if let dappWithoutIndex = dappsWithoutIndexes.first {
            sortedDapps.append(dappWithoutIndex)
            dappsWithoutIndexes.removeAtIndex(0)
          }
        }
      } else if let dappWithoutIndex = dappsWithoutIndexes.first {
        sortedDapps.append(dappWithoutIndex)
        dappsWithoutIndexes.removeAtIndex(0)
      }
    }
    
    // in case there are dapps left
    for dapp in dappsWithoutIndexes {
      sortedDapps.append(dapp)
    }
    
    return sortedDapps as [PFObject]
  }
}
