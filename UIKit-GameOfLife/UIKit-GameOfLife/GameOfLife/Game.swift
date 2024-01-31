//
//  Game.swift
//  UIKit-GameOfLife
//
//  Created by ashley canty on 1/26/24.
//

import Foundation


final class Game {
    
    static let dimension: Double = 10.0
    
    var cells = [Cell]()
    
    func resetStates(completion: @escaping (() -> Void)) {
        cells.forEach { $0.isAlive = false }
        completion()
    }
    
    /// Find's the selected cell by checking if the touchpoint is inside of the cell's frame
    func validateTouchpoint(touchPoint: CGPoint, completion: @escaping ((IndexPath?) -> Void)) {
        let selectedCells = cells.filter { cell in
            guard let frame = cell.frame, frame.minX...frame.maxX ~= touchPoint.x, frame.minY...frame.maxY ~= touchPoint.y else { return false }
            return true
        }
        
        guard let selectedCell = selectedCells.first else {
            completion(nil)
            return
        }
        selectedCell.isAlive = true
        completion(selectedCell.indexPath)
    }
    
    
    /// Returns true if the other cell is a neighbor
    private func isNextTo(_ cell: Cell, otherCell: Cell) -> Bool {
        guard let cellFrame = cell.frame, let otherCellFrame = otherCell.frame else { return false }
        
        /*
              minY
         .___.___.___.
         |___|___|___|
    minX |___|_X_|___| maxX
         |___|___|___|
              maxY
         */
        
        /// Get parameter values of the surrounding cells and check if otherCell's center is within range
        let rangeMinXToMaxX = (cellFrame.minX - cellFrame.width)...(cellFrame.maxX + cellFrame.width)
        let rangeMinYToMaxY = (cellFrame.minY - cellFrame.height)...(cellFrame.maxY + cellFrame.height)
        
        let isNotIdentical = otherCellFrame != cellFrame
        let isWithinRangeOnXAxis = (rangeMinXToMaxX ~= otherCellFrame.midX)
        let isWithinRangeOnYAxis = (rangeMinYToMaxY ~= otherCellFrame.midY)
        
        switch (isNotIdentical, isWithinRangeOnXAxis, isWithinRangeOnYAxis) {
        case (true, true, true):
            return true
        default:
            return false
        }
    }
    
    /// Returns int value of living neighbors
    private func livingNeighbors(for cell: Cell) -> Int {
        var neighborCount = 0
        cells.forEach { otherCell in
            if otherCell.isAlive && isNextTo(cell, otherCell: otherCell) {
                neighborCount += 1
            }
        }
        
        return  neighborCount
    }
    
    /// Creates a new collection of cell managers if they dont already exists. Or otherwise, creates the next generation of cells with updated states
    func iterate(completion: @escaping ((Bool) -> Void)) {
        if cells.isEmpty {
            let totalNumberOfCells = Int(pow(Game.dimension, 2))
            (0 ..< totalNumberOfCells).forEach { _ in cells.append(Cell()) }
            
        } else {
            
            guard let updatedCells = cells.map({ $0.copy() }) as? [Cell] else {
                completion(false)
                return
            }
            
            for x in 0 ..< cells.count {
                let cell = cells[x]
                let livingNeighbors = livingNeighbors(for: cell)
                
                if cell.isAlive {
                    if 2...3 ~= livingNeighbors {
                        updatedCells[x].isAlive = true
                    } else {
                        updatedCells[x].isAlive = false
                    }
                } else if livingNeighbors == 3 {
                    updatedCells[x].isAlive = true
                }
            }
            
            cells = updatedCells
        }
        
        completion(true)
    }
}
