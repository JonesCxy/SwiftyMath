//
//  LinkDrawing.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/18.
//

import Foundation
import SwiftyHomology

public extension Link {
    internal var gridDiagram: Grid2<Piece> {
        return GridDiagramGenerator(self).generate()
    }
    
    public func draw() {
        let grid = gridDiagram
        
        let degs = grid.bidegrees
        let (i0, i1) = (degs.map{ $0.0 }.min()!, degs.map{ $0.0 }.max()!)
        let (j0, j1) = (degs.map{ $0.1 }.min()!, degs.map{ $0.1 }.max()!)
        
        for j in (j0 ... j1).reversed() {
            let line = (i0 ... i1).map{ i in grid[i, j].map{ $0.description } ?? " " }.joined()
            print(line)
        }
    }
}

class Piece: CustomStringConvertible {
    var description: String { return "" }
}

final class EdgePiece: Piece {
    
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

final class CrossingPiece: Piece {
    let crossing: Link.Crossing
    
    init(_ crossing: Link.Crossing) {
        self.crossing = crossing
        super.init()
    }
    
    override var description: String {
        return "╂"
    }
}

final class GridDiagramGenerator {
    let L: Link
    
    typealias Edge = Link.Edge
    typealias Crossing = Link.Crossing
    
    var grid = Grid2<Piece>()
    var queue: [Crossing]
    var x0: Crossing!
    var (i0, j0) = (0, 0)
    
    init(_ L: Link) {
        self.L = L
        self.queue = L.crossings
    }
    
    func generate() -> Grid2<Piece> {
        assert(L.components.count <= 1) // for now
        
        if L.crossings.isEmpty {
            return grid
        }
        
        while !queue.isEmpty {
            placeCrossings()
        }
        
        return grid
    }
    
    func placeCrossings() {
        x0 = queue.removeFirst()
        grid[i0, j0] = CrossingPiece(x0)
        
        while queue.contains( x0.edge2.endPoint1.crossing ) {
            let e = x0.edge2
            let (x1, k) = e.endPoint1
            
            queue.remove(element: x1)
            
            switch k {
            case 0:
                add(e, x1, i0 + 1, j0)
            case 1:
                add(e, x1, i0 + 1, j0 + 1)
            case 3:
                add(e, x1, i0 + 1, j0 - 1)
            default:
                fatalError()
            }
        }
    }
    
    func add(_ e: Edge, _ x1: Crossing, _ i1: Int, _ j1: Int) {
        for i in (i0 + 1 ... i1) {
            if i < i1 {
                grid[i,  j0] = EdgePiece(.H, e)  // ─
            } else if j1 > j0 {
                grid[i1, j0] = EdgePiece(.BR, e) // ┚
            } else if j1 < j0 {
                grid[i1, j0] = EdgePiece(.TR, e) // ┒
            }
        }
        
        if j1 > j0 + 1 {
            for j in (j0 + 1 ... j1 - 1) {
                grid[i1, j] = EdgePiece(.V, e) // ┃
            }
        } else if j1 < j0 - 1 {
            for j in (j1 + 1 ... j0 - 1) {
                grid[i1, j] = EdgePiece(.V, e) // ┃
            }
        }
        
        grid[i1, j1] = CrossingPiece(x1)
        
//            print((i1, j1), ":", x1)
        
        (x0, i0, j0) = (x1, i1, j1)
    }

}
