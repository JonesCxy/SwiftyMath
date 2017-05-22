import Foundation

public struct Matrix<_R: Ring, n: _Int, m: _Int>: Module, Sequence, CustomStringConvertible {
    public typealias R = _R
    public let rows: Int
    public let cols: Int
    
    internal var grid: [R]
    
    private func index(_ i: Int, _ j: Int) -> Int {
        return (i * cols) + j
    }
    
    public subscript(index: Int) -> R {
        get {
            return grid[index]
        }
        set {
            grid[index] = newValue
        }
    }
    
    public subscript(i: Int, j: Int) -> R {
        get {
            return grid[index(i, j)]
        }
        set {
            grid[index(i, j)] = newValue
        }
    }
    
    // root initializer
    internal init(rows: Int, cols: Int, grid: [R]) {
        guard rows >= 0 && cols >= 0 else {
            fatalError("illegal matrix size (\(rows), \(cols))")
        }
        self.rows = rows
        self.cols = cols
        self.grid = grid
    }

    internal init(rows: Int, cols: Int, gen: (Int, Int) -> R) {
        let grid = (0 ..< rows * cols).map { (index: Int) -> R in
            let (i, j) = index /% cols
            return gen(i, j)
        }
        self.init(rows: rows, cols: cols, grid: grid)
    }

    public init(_ grid: R...) {
        if n.self == _TypeLooseSize.self || m.self == _TypeLooseSize.self {
            fatalError("attempted to initialize TypeLooseMatrix without specifying rows/cols.")
        }
        self.init(rows: n.value, cols: m.value, grid: grid)
    }
    
    public init(_ gen: (Int, Int) -> R) {
        if n.self == _TypeLooseSize.self || m.self == _TypeLooseSize.self {
            fatalError("attempted to initialize TypeLooseMatrix without specifying rows/cols.")
        }
        self.init(rows: n.value, cols: m.value, gen: gen)
    }
    
    public static var zero: Matrix<R, n, m> {
        return self.init { _ in 0 }
    }
    
    public var leftIdentity: Matrix<R, n, n> {
        return Matrix<R, n, n>(rows: rows, cols: rows) { $0 == $1 ? 1 : 0 }
    }
    
    public var rightIdentity: Matrix<R, m, m> {
        return Matrix<R, m, m>(rows: cols, cols: cols) { $0 == $1 ? 1 : 0 }
    }
    
    public var transpose: Matrix<R, m, n> {
        return Matrix<R, m, n>(rows: cols, cols: rows) { self[$1, $0] }
    }
}

public typealias ColVector<R: Ring, n: _Int> = Matrix<R, n, _1>
public typealias RowVector<R: Ring, m: _Int> = Matrix<R, _1, m>

public extension Matrix {
    public func rowArray(_ i: Int) -> [R] {
        return (0 ..< cols).map{ j in self[i, j] }
    }
    
    public func colArray(_ j: Int) -> [R] {
        return (0 ..< rows).map{ i in self[i, j] }
    }
    
    public func rowVector(_ i: Int) -> RowVector<R, m> {
        return RowVector<R, m>(rows: 1, cols: cols){(_, j) -> R in
            return self[i, j]
        }
    }
    
    public func colVector(_ j: Int) -> ColVector<R, n> {
        return ColVector<R, n>(rows: rows, cols: 1){(i, _) -> R in
            return self[i, j]
        }
    }
    
    func toRowVectors() -> [RowVector<R, m>] {
        return (0 ..< rows).map { rowVector($0) }
    }
    
    func toColVectors() -> [ColVector<R, n>] {
        return (0 ..< cols).map { colVector($0) }
    }
    
    func submatrix<m0: _Int>(colsInRange c: CountableRange<Int>) -> Matrix<R, n, m0> {
        return Matrix<R, n, m0>(rows: self.rows, cols: c.upperBound - c.lowerBound) {
            self[$0, $1 + c.lowerBound]
        }
    }
    
    func submatrix<n0: _Int>(rowsInRange r: CountableRange<Int>) -> Matrix<R, n0, m> {
        return Matrix<R, n0, m>(rows: r.upperBound - r.lowerBound, cols: self.cols) {
            self[$0 + r.lowerBound, $1]
        }
    }
    
    func submatrix<n0: _Int, m0: _Int>(inRange: (rows: CountableRange<Int>, cols: CountableRange<Int>)) -> Matrix<R, n0, m0> {
        let (r, c) = inRange
        return Matrix<R, n0, m0>(rows: r.upperBound - r.lowerBound, cols: c.upperBound - c.lowerBound) {
            self[$0 + r.lowerBound, $1 + c.lowerBound]
        }
    }
}

public extension ColVector {
    static func unit(_ i: Int) -> ColVector<R, n> {
        return ColVector<R, n>{ (j, _) in (i == j) ? 1 : 0 }
    }
    
    // MEMO this is used in case n == _TypeLooseSize
    static func unit(size: Int, _ i: Int) -> ColVector<R, n> {
        return ColVector<R, n>(rows: size, cols: 1){ (j, _) in (i == j) ? 1 : 0 }
    }
}

// Matrix Operations

public func == <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Bool {
    return R.matrixOperation.eq(a, b)
}

public func + <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return R.matrixOperation.add(a, b)
}

public prefix func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return R.matrixOperation.neg(a)
}

public func - <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, b: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return R.matrixOperation.sub(a, b)
}

public func * <R: Ring, n: _Int, m: _Int>(r: R, a: Matrix<R, n, m>) -> Matrix<R, n, m> {
    return R.matrixOperation.mul(r, a)
}

public func * <R: Ring, n: _Int, m: _Int>(a: Matrix<R, n, m>, r: R) -> Matrix<R, n, m> {
    return R.matrixOperation.mul(a, r)
}

public func * <R: Ring, n: _Int, m: _Int, p: _Int>(a: Matrix<R, n, m>, b: Matrix<R, m, p>) -> Matrix<R, n, p> {
    return R.matrixOperation.mul(a, b)
}

public func ** <R: Ring, n: _Int>(a: Matrix<R, n, n>, k: Int) -> Matrix<R, n, n> {
    return R.matrixOperation.pow(a, k)
}

// Elementary Matrix Operations (mutating)

public extension Matrix {
    public mutating func multiplyRow(at i: Int, by r: R) {
        R.matrixOperation.multiplyRow(&self, at: i, by: r)
    }
    
    public mutating func multiplyCol(at j: Int, by r: R) {
        R.matrixOperation.multiplyCol(&self, at: j, by: r)
    }
    
    public mutating func addRow(at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        R.matrixOperation.addRow(&self, at: i0, to: i1, multipliedBy: r)
    }
    
    public mutating func addCol(at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        R.matrixOperation.addCol(&self, at: j0, to: j1, multipliedBy: r)
    }
    
    public mutating func swapRows(_ i0: Int, _ i1: Int) {
        R.matrixOperation.swapRows(&self, i0, i1)
    }
    
    public mutating func swapCols(_ j0: Int, _ j1: Int) {
        R.matrixOperation.swapCols(&self, j0, j1)
    }
    
    public mutating func replaceElements(_ gen: (Int, Int) -> R) {
        R.matrixOperation.replaceElements(&self, gen)
    }
}

public extension Matrix {
    public var description: String {
        return "[" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ", ")
        }).joined(separator: "; ") + "]"
    }

    public var alignedDescription: String {
        return "[\t" + (0 ..< rows).map({ i in
            return (0 ..< cols).map({ j in
                return "\(self[i, j])"
            }).joined(separator: ",\t")
        }).joined(separator: "\n\t") + "]"
    }
    
    public static var symbol: String {
        return "M(\((n.self == _TypeLooseSize.self ? "?" : "\(n.value)")), \((m.self == _TypeLooseSize.self ? "?" : "\(m.value)")); \(R.symbol))"
    }
}

// Sequence / Iterator

public extension Matrix {
    public typealias Iterator = MatrixIterator<R, n, m>
    public func makeIterator() -> Iterator {
        return MatrixIterator(self)
    }
}

public struct MatrixIterator<R: Ring, n: _Int, m: _Int> : IteratorProtocol {
    private let value: Matrix<R, n, m>
    private var current = (0, 0)
    
    public init(_ value: Matrix<R, n, m>) {
        self.value = value
    }
    
    mutating public func next() -> (value: R, row: Int, col: Int)? {
        guard current.0 < value.rows && current.1 < value.cols else {
            return nil
        }
        
        defer {
            switch current {
            case let c where c.1 + 1 >= value.cols:
                current = (c.0 + 1, 0)
            case let c:
                current = (c.0, c.1 + 1)
            }
        }
        
        return (value[current.0, current.1], current.0, current.1)
    }
}

// SquareMatrix

public typealias SquareMatrix<R: Ring, n: _Int> = Matrix<R, n, n>

public extension Matrix where n == m {
    public static var identity: Matrix<R, n, n> {
        return self.init { $0 == $1 ? 1 : 0 }
    }

    public var det: R {
        return _determinant(self)
    }
}

// TypeLooseMatrix

public struct _TypeLooseSize : _Int { public static let value = 0 }
public typealias TypeLooseMatrix<R: Ring> = Matrix<R, _TypeLooseSize, _TypeLooseSize>

public extension Matrix where n == _TypeLooseSize, m == _TypeLooseSize {
    public init(_ rows: Int, _ cols: Int, _ grid: [R]) {
        self.init(rows: rows, cols: cols, grid: grid)
    }
    
    public init(_ rows: Int, _ cols: Int, _ gen: (Int, Int) -> R) {
        self.init(rows: rows, cols: cols, gen: gen)
    }
}

// Matrix Elimination
public extension Matrix where R: EuclideanRing {
    public func eliminate(mode: MatrixEliminationMode = .Both) -> BaseMatrixElimination<R, n, m> {
        return R.matrixElimination(self, mode: mode)
    }
}

// FIXME this implementation is a disaster.
private func _determinant<R: Ring, n: _Int>(_ a: Matrix<R, n, n>) -> R {
    return Permutation<n>.all.reduce(0) {
        (res: R, s: Permutation<n>) -> R in
        res + R(sgn(s)) * (0 ..< a.rows).reduce(1) {
            (p: R, i: Int) -> R in
            p * a[i, s[i]]
        }
    }
}

// Matrix Operation Implementation
// Operations are extracted from the concrete struct for extensibility.

private var instanceStorage: [String: Any] = [:] // since generic type cannot have stored static vars.

public class BaseMatrixOperation<R: Ring> {
    public class var sharedInstance: BaseMatrixOperation {
        let key = "\(R.self)"
        if let s = instanceStorage[key] as? BaseMatrixOperation<R> {
            return s
        } else {
            let s = BaseMatrixOperation<R>()
            instanceStorage[key] = s
            return s
        }
    }
    internal init() {}
    
    public func eq<n: _Int, m: _Int>(_ a: Matrix<R, n, m>, _ b: Matrix<R, n, m>) -> Bool {
        return a.grid == b.grid
    }
    
    public func add<n: _Int, m: _Int>(_ a: Matrix<R, n, m>, _ b: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] + b[i, j]
        }
    }
    
    public func neg<n: _Int, m: _Int>(_ a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return -a[i, j]
        }
    }
    
    public func sub<n: _Int, m: _Int>(_ a: Matrix<R, n, m>, _ b: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] - b[i, j]
        }
    }
    
    public func mul<n: _Int, m: _Int>(_ r: R, _ a: Matrix<R, n, m>) -> Matrix<R, n, m> {
        return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return r * a[i, j]
        }
    }
    
    public func mul<n: _Int, m: _Int>(_ a: Matrix<R, n, m>, _ r: R) -> Matrix<R, n, m> {
        return Matrix<R, n, m>(rows: a.rows, cols: a.cols) { (i, j) -> R in
            return a[i, j] * r
        }
    }
    
    public func mul<n: _Int, m: _Int, p: _Int>(_ a: Matrix<R, n, m>, _ b: Matrix<R, m, p>) -> Matrix<R, n, p> {
        return Matrix<R, n, p>(rows: a.rows, cols: b.cols) { (i, k) -> R in
            return (0 ..< a.cols)
                .map({j in a[i, j] * b[j, k]})
                .reduce(0) {$0 + $1}
        }
    }
    
    public func pow<n: _Int>(_ a: Matrix<R, n, n>, _ k: Int) -> Matrix<R, n, n> {
        return k == 0 ? a.leftIdentity : a * (a ** (k - 1))
    }

    public func multiplyRow<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, at i: Int, by r: R) {
        for j in 0 ..< m.cols {
            m[i, j] = r * m[i, j]
        }
    }
    
    public func multiplyCol<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, at j: Int, by r: R) {
        for i in 0 ..< m.rows {
            m[i, j] = r * m[i, j]
        }
    }
    
    public func addRow<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, at i0: Int, to i1: Int, multipliedBy r: R = 1) {
        for j in 0 ..< m.cols {
            m[i1, j] = m[i1, j] + (m[i0, j] * r)
        }
    }
    
    public func addCol<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, at j0: Int, to j1: Int, multipliedBy r: R = 1) {
        for i in 0 ..< m.rows {
            m[i, j1] = m[i, j1] + (m[i, j0] * r)
        }
    }
    
    public func swapRows<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, _ i0: Int, _ i1: Int) {
        for j in 0 ..< m.cols {
            let a = m[i0, j]
            m[i0, j] = m[i1, j]
            m[i1, j] = a
        }
    }
    
    public func swapCols<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, _ j0: Int, _ j1: Int) {
        for i in 0 ..< m.rows {
            let a = m[i, j0]
            m[i, j0] = m[i, j1]
            m[i, j1] = a
        }
    }
    
    public func replaceElements<n: _Int, m: _Int>(_ m: inout Matrix<R, n, m>, _ gen: (Int, Int) -> R) {
        for i in 0 ..< m.rows {
            for j in 0 ..< m.cols {
                m[i, j] = gen(i, j)
            }
        }
    }

}
