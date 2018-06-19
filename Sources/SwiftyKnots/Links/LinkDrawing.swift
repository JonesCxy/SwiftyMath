//
//  LinkDrawing.swift
//  Sample
//
//  Created by Taketo Sano on 2018/06/18.
//

import Foundation
import SwiftyHomology

typealias Edge = Link.Edge
typealias Crossing = Link.Crossing

public extension Link {
    internal var gridDiagram: Grid2<GridDiagramPiece> {
        return GridDiagramGenerator(self).generate()
    }
    
    public func draw() {
        print(self.name, "\n")
        
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

enum GridDiagramPiece: CustomStringConvertible {
    case TL(edge: Edge) // ┎
    case TR(edge: Edge) // ┒
    case BL(edge: Edge) // ┖
    case BR(edge: Edge) // ┚
    case  H(edge: Edge) // ─
    case  V(edge: Edge) // ┃
    case  X(crossing: Crossing) // ╂
    
    var description: String {
        switch self {
        case .TL(_): return "┎"
        case .TR(_): return "┒"
        case .BL(_): return "┖"
        case .BR(_): return "┚"
        case  .H(_): return "─"
        case  .V(_): return "┃"
        case  .X(_): return "╂"
        }
    }
}

final class GridDiagramGenerator {
    let L: Link
    
    var grid = Grid2<GridDiagramPiece>()
    var crossingQueue : [Crossing]
    var (i0, j0) = (0, 0)
    
    init(_ L: Link) {
        self.L = L
        self.crossingQueue = L.crossings
    }
    
    func generate() -> Grid2<GridDiagramPiece> {
        assert(L.components.count <= 1) // for now
        
        if L.crossings.isEmpty {
            return grid
        }
        
        while !crossingQueue.isEmpty {
            let x0 = crossingQueue.removeFirst()
            placeCrossings(from: x0)
        }
        
        return grid
    }
    
    func placeCrossings(from x: Crossing) {
        var x0 = x
        placeCrossing(x0, i0, j0)
        
        while crossingQueue.contains( x0.edge2.endPoint1.crossing ) {
            let e = x0.edge2
            let (x1, k) = e.endPoint1
            
            crossingQueue.remove(element: x1)
            
            switch k {
            case 0:
                placeNextCrossing(e, x1, i0 + 1, j0)
            case 1:
                placeNextCrossing(e, x1, i0 + 1, j0 + 1)
            case 3:
                placeNextCrossing(e, x1, i0 + 1, j0 - 1)
            default:
                fatalError()
            }
            
            x0 = x1
        }
    }
    
    func placeCrossing(_ x: Crossing, _ i: Int, _ j: Int) {
        grid[i, j] = .X(crossing: x)
        (i0, j0) = (i, j)
        
        print((i, j), ":", x)
    }
    
    func placeNextCrossing(_ e: Edge, _ x1: Crossing, _ i1: Int, _ j1: Int) {
        for i in (i0 + 1 ... i1) {
            if i < i1 {
                grid[i,  j0] =  .H(edge: e)  // ─
            } else if j1 > j0 {
                grid[i1, j0] = .BR(edge: e) // ┚
            } else if j1 < j0 {
                grid[i1, j0] = .TR(edge: e) // ┒
            }
        }
        
        if j1 > j0 + 1 {
            for j in (j0 + 1 ... j1 - 1) {
                grid[i1, j] = .V(edge: e) // ┃
            }
        } else if j1 < j0 - 1 {
            for j in (j1 + 1 ... j0 - 1) {
                grid[i1, j] = .V(edge: e) // ┃
            }
        }
        
        placeCrossing(x1, i1, j1)
    }
}
