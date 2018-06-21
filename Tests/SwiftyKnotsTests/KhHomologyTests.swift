//
//  KHTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
import SwiftyHomology
@testable import SwiftyKnots

extension Link {
    public func describeResolution(_ s: IntList) {
        assert(self.components.count == 1) // currently supports only knots.
        
        print(s)
        
        let L0 = self.spliced(by: s)
        let comps = L0.components
        
        for (i, c) in comps.enumerated() {
            print("\t", "(\(i))", c)
            
            // crossings that touches c
            let xs = crossings.filter{ x in
                x.edges.contains{ e in c.edges.contains(e) }
            }
            
            // circles that are connected to c by xs
            let cs = xs.map { x -> (Crossing, Component) in
                let e = x.edges.first { e in !c.edges.contains(e) } ?? x.edge0
                let c1 = comps.first{ c1 in c1.edges.contains(e) }!
                return (x, c1)
            }
                .group{ $0.1 }
                .map { (x, list) -> (Int, Component) in
                    (list.sum{ (x, _) in x.crossingSign }, c)
                }
                .sorted{ $0.1 < $1.1 }
            
            for (i, c) in cs {
                print("\t\t", (i > 0 ? "+\(i)" : "\(i)"), c)
            }
        }
    }
    
    public func shits<R: EuclideanRing>(_ type: R.Type) -> [FreeModule<KhBasisElement, R>] {
        assert(self.components.count == 1) // currently supports only knots.
        
        let s0 = orientationPreservingState
        let L0 = self.spliced(by: s0)
        let comps = L0.components
        
//        for x in crossings {
//            print(x.id, x, x.crossingSign < 0 ? "-" : "+")
//        }
        
//        print("comps: \(comps.count) \(comps)")
        
        let negs = comps.enumerated().compactMap { (i, c) -> Int? in
            let touching = crossings.filter { x in
                x.edges.contains{ e in c.edges.contains(e) }
            }
            return touching.forAll{ $0.crossingSign == -1 } ? i : nil
        }
        
//        print("strongly-negatives: \(negs.count) \(negs.map{ i in comps[i] })")
        
        let basis = LeeHomologyGenerators(R.self)
        let xiBasis = [(basis[0] - basis[1]).mapValues{ $0 / R(from: 2) }, (basis[0] + basis[1]).mapValues{ $0 / R(from: 2) }]
        
        return negs.reduce(xiBasis) { (res, i) -> [FreeModule<KhBasisElement, R>] in
            res.flatMap { z -> [FreeModule<KhBasisElement, R>] in
                z.elements.group{ $0.key.tensor.factors[i] }.map { _, list in
                    FreeModule(list)
                }
            }
        }
    }
}

class KhHomologyTests: XCTestCase {
    
    func test() {
        typealias R = 𝐙
        
        var ohs: [Link] = []
        var goods: [Link] = []
        
        for K in Link.list(.knot, crossing: 10).flatMap({[$0, $0.mirrored]}) {
            
            let C = K.LeeChainComplex(R.self)
//            let B = C.boundary(IntList(0))!
            let H = C.homology(0)!
            
//            H.describe()
            
            let xiBasis = K.shits(R.self)
            
            for z in xiBasis {
                let v = H.factorize(z)
                if v.contains(where: { $0.abs > 1 }) {
                    print("oh: \(K.name)")
                    print(z, "=", v)
                    
                    ohs.append(K)
                    
//                    let w = v.enumerated().sum{ (i, a) in a * H.generator(i) }
//                    let b = B.factorize(z - w).enumerated().sum{ (i, a) in a * B.generator(i) } // z = w + b
//                    print("boundary:", b)
//
//                    print(z - b)
                    
                    let basis = z.basis
                    let n = z.elements.count
                    
                    if n >= 16 {
                        print("skip")
                        break
                    }
                    
                    for s in n.choose(n/2) {
                        let w = s.sum { i -> FreeModule<KhBasisElement, R> in
                            let x = basis[i]
                            return z[x] * .wrap(x)
                        }
                        
                        if C.d[0].applied(to: w) == .zero {
                            print("\t", w, "=", H.factorize(w))
                            
                            for (x, a) in w.elements {
                                print(a * .wrap(x), " -> ", a * C.d[0].applied(to: x))
                            }
                            
                            goods.append(K)

                            break
                        }
                    }
                    print()
                    break
                }
                print()
                break
            }

        }
        
        print("ohs:", ohs)
        print("goods:", goods)
    }
    
    func run(_ K: Link) {
        typealias R = 𝐙
        
        let C = K.LeeChainComplex(R.self)
        let B = C.boundary(IntList(0))!
        let H = C.homology(0)!
        
        H.describe()
        
        let xiBasis = K.shits(R.self)
        
        for z in xiBasis {
            let v = H.factorize(z)
            if v.contains(where: { $0.abs > 1 }) {
                print("oh: \(K.name)")
                print(z, "=", v)
                
                let w = v.enumerated().sum{ (i, a) in a * H.generator(i) }
                let b = B.factorize(z - w).enumerated().sum{ (i, a) in a * B.generator(i) } // z = w + b
                print("boundary:", b)
                
                print(z - b)
                
//                let basis = z.basis
//                let n = z.elements.count
//                for s in n.choose(n/2) {
//                    let w = s.sum { i -> FreeModule<KhBasisElement, R> in
//                        let x = basis[i]
//                        return z[x] * .wrap(x)
//                    }
//
//                    if C.d[0].applied(to: w) == .zero {
//                        print("\t", w, "=", H.factorize(w))
//
//                        for (x, a) in w.elements {
//                            print(a * .wrap(x), " -> ", a * C.d[0].applied(to: x))
//                        }
//                    }
//                }
//                print()
                break
            }
            print()
            break
        }
    }
    
    func testUnknot() {
        let K = Link.unknot
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
        XCTAssertEqual(Kh.bidegrees.count, 2)
        XCTAssertEqual(Kh[0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[0,  1]!.structure, [0 : 1])
    }
    
    func testUnknot_RM1() {
        let K = Link(planarCode: [1,2,2,1])
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.structureCode, Link.unknot.KhHomology(𝐙.self).structureCode)
    }
    
    func testUnknot_RM2() {
        let K = Link(planarCode: [1,4,2,1], [2,4,3,3])
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.structureCode, Link.unknot.KhHomology(𝐙.self).structureCode)
    }
    
    func test3_1_Z() {
        let K = Knot(3, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
        
        XCTAssertEqual(Kh.bidegrees.count, 5)
        XCTAssertEqual(Kh[-3, -9]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-2, -7]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-2, -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-0, -3]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-0, -1]!.structure, [0 : 1])
    }
    
    func test4_1_Z() {
        let K = Knot(4, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
        
        XCTAssertEqual(Kh.bidegrees.count, 8)
        XCTAssertEqual(Kh[-2, -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-1, -3]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-1, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 1,  1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 2,  3]!.structure, [2 : 1])
        XCTAssertEqual(Kh[ 2,  5]!.structure, [0 : 1])
    }
    
    func test5_1_Z() {
        let K = Knot(5, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.bidegrees.count, 8)
        XCTAssertEqual(Kh[-5, -15]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-4, -13]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-4, -11]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-3, -11]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-2,  -9]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-2,  -7]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0,  -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0,  -3]!.structure, [0 : 1])

    }
}
