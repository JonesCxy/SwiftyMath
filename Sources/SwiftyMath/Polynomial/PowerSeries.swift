//
//  PowerSeries.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/03/12.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public struct PowerSeries<R: Ring>: Ring, Module {
    public typealias CoeffRing = R
    public let coeffs: (Int) -> R
    
    public init(from n: 𝐙) {
        self.init() { i in
            (i == 0) ? R(from: n) : .zero
        }
    }
    
    public init(_ coeffs: R ...) {
        self.init(coeffs)
    }
    
    public init(_ coeffs: [R]) {
        self.init() { i in
            (i < coeffs.count) ? coeffs[i] : .zero
        }
    }
    
    public init(_ coeffs: @escaping ((Int) -> R)) {
        self.coeffs = coeffs
    }
    
    public var inverse: PowerSeries<R>? {
        guard let b0 = constantTerm.inverse else {
            return nil
        }
        
        var list = [b0]
        func invCoeff(_ i: Int) -> R {
            if i < list.count { return list[i] }
            let b_i = -b0 * (1 ... i).sum{ j in coeff(j) * invCoeff(i - j) }
            list.append(b_i)
            return b_i
        }
        return PowerSeries<R> { i in invCoeff(i) }
    }
    
    public func coeff(_ i: Int) -> R {
        assert(i >= 0)
        return coeffs(i)
    }
    
    public var constantTerm: R {
        return self.coeff(0)
    }
    
    public func map(_ f: @escaping (R) -> R ) -> PowerSeries<R> {
        return PowerSeries<R>.init() { i in
            f( self.coeffs(i) )
        }
    }
    
    public func polynomial(upTo degree: Int) -> Polynomial_x<R> {
        return Polynomial(coeffs: (0 ... degree).map{ i in coeff(i) } )
    }
    
    public func evaluate(_ x: R, upTo degree: Int) -> R {
        return polynomial(upTo: degree).evaluate(x)
    }
    
    public func evaluate<n>(_ x: SquareMatrix<n, R>, upTo degree: Int) -> SquareMatrix<n, R> {
        return polynomial(upTo: degree).evaluate(x)
    }
    
    public static func == (f: PowerSeries<R>, g: PowerSeries<R>) -> Bool {
        fatalError("== not available for PowerSeries.")
    }
    
    public static func + (f: PowerSeries<R>, g: PowerSeries<R>) -> PowerSeries<R> {
        return PowerSeries<R>() { i in
            f.coeff(i) + g.coeff(i)
        }
    }
    
    public static prefix func - (f: PowerSeries<R>) -> PowerSeries<R> {
        return f.map { -$0 }
    }
    
    public static func * (f: PowerSeries<R>, g: PowerSeries<R>) -> PowerSeries<R> {
        return PowerSeries<R> { i in
            (0 ... i).sum { j in
                f.coeff(j) * g.coeff(i - j)
            }
        }
    }
    
    public static func * (r: R, f: PowerSeries<R>) -> PowerSeries<R> {
        return f.map { r * $0 }
    }
    
    public static func * (f: PowerSeries<R>, r: R) -> PowerSeries<R> {
        return f.map { $0 * r }
    }
    
    public var description: String {
        return Format.terms("+", (0 ..< 5).map{ n in (coeff(n), "x", n) }) + " ..."
    }
    
    public static var symbol: String {
        return "\(R.symbol)[[x]]"
    }
    
    public func hash(into hasher: inout Hasher) {
        for i in 0 ..< 5 {
            hasher.combine(coeff(i))
        }
    }
}

public extension PowerSeries {
    public static var exponential: PowerSeries<R> {
        return PowerSeries { n in
            R(from: n.factorial).inverse!
        }
    }
    
    public static func geometricSeries(_ r: R) -> PowerSeries<R> {
        return PowerSeries { n in r.pow(n) }
    }
}

public struct MultiplicativeSequence<R: Ring>: CustomStringConvertible {
    internal let map: (Int) -> MPolynomial<R>
    
    public init(belongingTo f: PowerSeries<R>) {
        self.map = { n in
            let Is = n.partitions
            return Is.sum { I in
                let c = I.components.multiply { i in f.coeff(i) }
                let s_I = SymmetricPolynomial<R>.monomial(n, I).elementaryDecomposition()
                return c * s_I
            }
        }
    }
    
    public subscript(n: Int) -> MPolynomial<R> {
        return map(n)
    }
    
    public var description: String {
        return (0 ..< 5).map{ self[$0].description }.joined(separator: " + ") + " ..."
    }
}

public extension MultiplicativeSequence where R == 𝐐 {
    public static var HirzebruchL: MultiplicativeSequence<R> {
        let B = BernoulliNumber
        let f = PowerSeries<R> { n in
            (n == 0) ? 1 : R(2.pow(2 * n), (2 * n).factorial) * B(2 * n)
        }
        return MultiplicativeSequence(belongingTo: f)
    }
}
