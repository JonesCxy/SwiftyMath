//
//  LinkDrawing.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/18.
//

import Foundation
import SwiftyHomology

public extension Link {
    public func draw() {
        if crossings.isEmpty {
            return
        }
        
        var grid = Grid2<Piece>()
        var queue = crossings
        var p = (0, 0)
        
        while !queue.isEmpty {
            var x0 = queue.removeFirst()
            
            grid[p.0, p.1] = CrossingPiece(x0)
            print(p, ": ", x0)
            
            while queue.contains( x0.edge2.endPoint1.crossing ) {
                let e = x0.edge2
                let (x1, i) = e.endPoint1
                
                queue.remove(element: x1)
                
                switch i {
                case 0:
                    grid[p.0 + 1, p.1] = CrossingPiece(x1)
                    p = (p.0 + 1, p.1)
                case 1:
                    grid[p.0 + 1, p.1] = EdgePiece(.BR, e)
                    grid[p.0 + 1, p.1 + 1] = CrossingPiece(x1)
                    p = (p.0 + 1, p.1 + 1)
                case 3:
                    grid[p.0 + 1, p.1] = EdgePiece(.TR, e)
                    grid[p.0 + 1, p.1 - 1] = CrossingPiece(x1)
                    p = (p.0 + 1, p.1 - 1)
                default:
                    fatalError()
                }
                
                print(p, ": ", x1)
                x0 = x1
            }
        }
        grid.printTable()
    }
}

class Piece: CustomStringConvertible {
    var description: String { return "" }
}

class EdgePiece: Piece {
    
    let type: T
    let edge: Link.Edge
    
    init(_ type: T, _ edge: Link.Edge) {
        self.type = type
        self.edge = edge
        super.init()
    }
    
    override var description: String {
        return type.rawValue
    }
    
    enum T: String {
        case TL = "┎"
        case TR = "┒"
        case BL = "┖"
        case BR = "┚"
        case H  = "─"
        case V  = "┃"
    }
}

class CrossingPiece: Piece {
    let crossing: Link.Crossing
    
    init(_ crossing: Link.Crossing) {
        self.crossing = crossing
        super.init()
    }
    
    override var description: String {
        return "╂"
    }
}
