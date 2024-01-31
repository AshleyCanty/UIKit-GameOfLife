//
//  Cell.swift
//  UIKit-GameOfLife
//
//  Created by ashley canty on 1/27/24.
//

import Foundation
import UIKit


class Cell: NSCopying {
    var indexPath: IndexPath?
    var frame: CGRect?
    var isAlive: Bool
    
    init(isAlive: Bool = false) {
        self.isAlive = false
    }
    
    func set(_ indexPath: IndexPath,_ frame: CGRect) {
        self.indexPath = indexPath
        self.frame = frame
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Cell(isAlive: isAlive)
        return copy
    }
}
