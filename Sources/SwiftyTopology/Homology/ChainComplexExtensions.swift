//
//  GeometricComplexExtensions.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/02/10.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension GeometricComplex {
    public func chainComplex<R: Ring>(relativeTo L: Self? = nil, _ type: R.Type) -> ChainComplex<Cell, R> {
        if let L = L { // relative: (K, L)
            return _chainComplex(relativeTo: L, type)
        } else {
            return _chainComplex(R.self)
        }
    }

    private func _chainComplex<R: Ring>(_ type: R.Type) -> ChainComplex<Cell, R> {
        typealias C = ChainComplex<Cell, R>
        let name = "C(\(self.name); \(R.symbol))"
        let gens = validDims.map { i in cells(ofDim: i) }
        let base = C.Base(name: name, generators: gens.toDictionary())
        let d = C.Differential.uniform(degree: -1) { (cell: Cell) in
            cell.boundary(R.self)
        }
        return C(base: base, differential: d)
    }
    
    private func _chainComplex<R: Ring>(relativeTo L: Self, _ type: R.Type) -> ChainComplex<Cell, R> {
        typealias C = ChainComplex<Cell, R>
        let name = "C(\(self.name), \(L.name); \(R.symbol))"
        let gens = validDims.map { i in cells(ofDim: i).subtract(L.cells(ofDim: i)) }
        let base = C.Base(name: name, generators: gens.toDictionary())
        let d = C.Differential(degree: -1) { i in
            FreeModuleHom { (cell: Cell) in
                cell.boundary(R.self).map { (cell, r) in
                    (i > 0 && gens[i - 1].contains(cell)) ? r * .wrap(cell) : .zero
                }
            }
        }
        return C(base: base, differential: d)
    }
    
    public func homology<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ModuleGrid1<Cell, R> {
        let name = (L == nil) ? "H(\(self.name); \(R.symbol))" : "H(\(self.name), \(L!.name); \(R.symbol))"
        let C = chainComplex(relativeTo: L, type)
        return C.homology().named(name)
    }
    
    public func cochainComplex<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ChainComplex<Dual<Cell>, R> {
        let name = (L == nil) ? "cC(\(self.name); \(R.symbol))" : "cC(\(self.name), \(L!.name); \(R.symbol))"
        return chainComplex(relativeTo: L, type).dual(name: name)
    }
    
    public func cohomology<R: EuclideanRing>(relativeTo L: Self? = nil, _ type: R.Type) -> ModuleGrid1<Dual<Cell>, R> {
        let name = (L == nil) ? "cH(\(self.name); \(R.symbol))" : "cH(\(self.name), \(L!.name); \(R.symbol))"
        let C = cochainComplex(relativeTo: L, type)
        return C.homology().named(name)
    }
}
