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

enum GridDiagramPiece: CustomStringConvertible, CustomDebugStringConvertible {
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
    
    var debugDescription: String {
        switch self {
        case let .TL(e): return "┎(\(e.id))"
        case let .TR(e): return "┒(\(e.id))"
        case let .BL(e): return "┖(\(e.id))"
        case let .BR(e): return "┚(\(e.id))"
        case let  .H(e): return "─(\(e.id))"
        case let  .V(e): return "┃(\(e.id))"
        case let  .X(x): return "╂(\(x))"
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
        
        for x in L.crossings {
            connectEdges(x)
        }
        
        return grid
    }
    
    func place(_ p: GridDiagramPiece, _ i: Int, _ j: Int) {
        print("place", (i, j), "\t", p.debugDescription)
        if grid[i, j] != nil {
            print("\toverride", grid[i, j]!.debugDescription)
            fatalError()
        }
        grid[i, j] = p
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
        place(.X(crossing: x), i, j)
        (i0, j0) = (i, j)
    }
    
    func placeNextCrossing(_ e: Edge, _ x1: Crossing, _ i1: Int, _ j1: Int) {
        for i in (i0 + 1 ... i1) {
            if i < i1 {
                place( .H(edge: e),  i, j0)  // ─
            } else if j1 > j0 {
                place(.BR(edge: e), i1, j0)  // ┚
            } else if j1 < j0 {
                place(.TR(edge: e), i1, j0)  // ┒
            }
        }
        
        if j1 > j0 + 1 {
            for j in (j0 + 1 ... j1 - 1) {
                place( .V(edge: e), i1,  j)  // ┃
            }
        } else if j1 < j0 - 1 {
            for j in (j1 + 1 ... j0 - 1) {
                place( .V(edge: e), i1,  j)  // ┃
            }
        }
        
        placeCrossing(x1, i1, j1)
    }
    
    func pos(_ x: Crossing) -> (Int, Int) {
        return grid.bidegrees.first{ (i, j) in
            switch grid[i, j]! {
            case .X(x): return true
            default: return false
            }
        }!
    }
    
    func connectEdges(_ x: Crossing) {
        let (i, j) = pos(x)
        if grid[i - 1, j] == nil && x.edge0.endPoint0 == (x, 0) {
            connectEdge(x, 0)
        }
        if grid[i, j - 1] == nil && x.edge1.endPoint0 == (x, 1) {
            connectEdge(x, 1)
        }
        if grid[i + 1, j] == nil && x.edge2.endPoint0 == (x, 2) {
            connectEdge(x, 2)
        }
        if grid[i, j + 1] == nil && x.edge3.endPoint0 == (x, 3) {
            connectEdge(x, 3)
        }
    }
    
    func connectEdge(_ x0: Crossing, _ k0: Int) {
        let (i0, j0) = pos(x0)
        let e = x0.edges[k0]
        let (x1, k1) = e.endPoint1
        let (i1, j1) = pos(x1)
        
        

        print("connect ", (pos(x0), k0), "->", (pos(x1), k1))
    }
}
