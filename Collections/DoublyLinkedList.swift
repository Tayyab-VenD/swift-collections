//
//  DoublyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 13/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

fileprivate typealias Node<Element> = LinkedListNode<Element>

public struct LinkedListIterator<Element> : IteratorProtocol {
    private let uniqueness: AnyObject
    private var current: Node<Element>?
    private let last: Node<Element>?

    fileprivate init(uniqueness: AnyObject, first: Node<Element>?, last: Node<Element>?) {
        self.uniqueness = uniqueness
        self.current = first
        self.last = last
    }

    public mutating func next() -> Element? {
        if current !== last {
            defer {
                current = current?.next
            }

            return current!.element
        }

        return nil
    }
}

public struct LinkedListIndex<Element> : Comparable {
    fileprivate unowned var identity: AnyObject
    fileprivate var offset: Int
    fileprivate var node: LinkedListNode<Element>

    public static func ==(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return lhs.node === rhs.node
    }

    public static func <(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset && lhs.node !== rhs.node)
    }
}

fileprivate final class UnsafeLinkedList<Element> {
    var head: Node<Element>

    init() {
        head = Node()
        head.next = head
        head.previous = head
    }

    deinit {
        // Break the retain cycle.
        head.next = nil
    }

    private init(head: LinkedListNode<Element>) {
        self.head = head
    }

    private init(chain: LinkedListChain<Element>) {
        // Make the chain circular.
        chain.tail.next = chain.head
        chain.head.previous = chain.tail

        // Setup head
        head = chain.head
    }

    func makeClone(mark node: inout Node<Element>) -> UnsafeLinkedList<Element> {
        let chain = LinkedListChain(head: head, tail: head.previous!)
        return UnsafeLinkedList(chain: cloneChain(chain, mark: &node))
    }

    func makeClone(skippingAfter first: inout Node<Element>, skippingBefore last: inout Node<Element>) -> UnsafeLinkedList<Element> {
        guard first !== last else {
            let clone = makeClone(mark: &first)
            last = first

            return clone
        }

        let leadingChain = cloneChain(LinkedListChain(head: head.next!, tail: first), mark: &first)
        let trailingChain = cloneChain(LinkedListChain(head: last, tail: head), mark: &last)

        // Attach leading and trailing chains.
        trailingChain.head.previous = leadingChain.tail
        leadingChain.tail.next = trailingChain.head

        // Make the chain circular.
        trailingChain.tail.next = leadingChain.head
        leadingChain.head.previous = trailingChain.tail

        return UnsafeLinkedList(head: trailingChain.tail)
    }
}

public struct LinkedList<Element> {
    private var unsafe: UnsafeLinkedList<Element>
    private var range: Range<Index>? // For slice index compatibility

    public init() {
        unsafe = UnsafeLinkedList()
    }

    private init(list: LinkedList<Element>, bounds: Range<Index>) {
        range = bounds
        unsafe = list.unsafe
    }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.init()
        append(contentsOf: elements)
    }

    private mutating func ensureUnique() {
        var mark = unsafe.head
        ensureUnique(mark: &mark)
    }

    private mutating func ensureUnique(mark node: inout Node) {
        if isKnownUniquelyReferenced(&unsafe) {
            return
        }

        unsafe = unsafe.makeClone(mark: &node)
    }

    private mutating func ensureUnique(skippingAfter first: inout Node, skippingBefore last: inout Node) {
        if isKnownUniquelyReferenced(&unsafe) {
            return
        }

        unsafe = unsafe.makeClone(skippingAfter: &first, skippingBefore: &last)
    }

    private mutating func ensureUnique(skipAll: Bool) {
        if isKnownUniquelyReferenced(&unsafe) {
            return
        }

        unsafe = UnsafeLinkedList()
    }

    private func failEarlyInsertionIndexCheck(_ index: Index) {
        precondition(index.identity === unsafe, "Invalid Index")
    }

    private func failEarlyRetrievalIndexCheck(_ index: Index) {
        precondition(index.identity === unsafe, "Invalid Index")
        precondition(index.node !== unsafe.head, "Index out of bounds")
    }

    private func failEarlyRangeCheck(_ range: Range<Index>) {
        precondition(
            range.lowerBound.identity === unsafe && range.upperBound.identity === unsafe,
            "Invalid Range Bounds")
    }
}

extension LinkedList : Sequence {
    public typealias Iterator = LinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return Iterator(uniqueness: unsafe, first: unsafe.head.next!, last: unsafe.head.previous!)
    }
}

extension LinkedList : LinkedCollection {
    public typealias Index = LinkedListIndex<Element>
    public typealias Node = LinkedListNode<Element>
    public typealias SubSequence = LinkedList<Element>

    public var startIndex: Index {
        if range == nil {
            return Index(identity: unsafe, offset: 0, node: unsafe.head.next!)
        }

        return range!.lowerBound
    }

    public var endIndex: Index {
        if range == nil {
            return Index(identity: unsafe, offset: Int.max, node: unsafe.head)
        }

        return range!.upperBound
    }

    public func index(after i: Index) -> Index {
        return Index(
            identity: i.identity,
            offset: i.offset + 1,
            node: i.node.next!)
    }

    public func formIndex(after i: inout Index) {
        i.offset += 1
        i.node = i.node.next!
    }

    public func distance(from start: Index, to end: Index) -> Int {
        var distance: Int = 0

        let last = end.node
        var node: Node? = start.node

        while node !== last {
            distance += 1
            node = node?.next
        }

        return distance
    }

    public var count: Int {
        return distance(from: startIndex, to: endIndex)
    }

    public var isEmpty: Bool {
        return unsafe.head === unsafe.head.next
    }

    public var first: Element? {
        let node = unsafe.head.next
        if node !== unsafe.head {
            return node!.element
        }

        return nil
    }

    public func node(at position: Index) -> Node {
        failEarlyRetrievalIndexCheck(position)
        return position.node
    }

    public subscript(position: Index) -> Element {
        get {
            failEarlyRetrievalIndexCheck(position)
            return position.node.element
        }
        set(element) {
            failEarlyInsertionIndexCheck(position)
            position.node.element = element
        }
    }

    public subscript(bounds: Range<Index>) -> LinkedList<Element> {
        get {
            failEarlyRangeCheck(bounds)
            return LinkedList(list: self, bounds: bounds)
        }
        set(slice) {
            failEarlyRangeCheck(bounds)

            var first = bounds.lowerBound.node
            var last = bounds.upperBound.node
            ensureUnique(skippingAfter: &first, skippingBefore: &last)

            if !slice.isEmpty {
                // Clone the slice nodes.
                var mark = slice.startIndex.node
                let chain = cloneChain(LinkedListChain(head: slice.startIndex.node, tail: slice.endIndex.node.previous!), mark: &mark)
                
                attach(chain: chain, after: first.previous!, before: last)
            } else {
                // Slice has no element.
                abandon(after: first.previous!, before: last)
            }
        }
    }

    public mutating func swapAt(_ i: Index, _ j: Index) {
        failEarlyRetrievalIndexCheck(i)
        failEarlyRetrievalIndexCheck(j)

        let first = i.node
        let second = j.node

        let temp = first.element
        first.element = second.element
        second.element = temp
    }
}

extension LinkedList : BidirectionalCollection {
    public func formIndex(before i: inout Index) {
        i.offset -= 1
        i.node = i.node.previous!
    }

    public func index(before i: Index) -> Index {
        return Index(
            identity: i.identity,
            offset: i.offset + 1,
            node: i.node.previous!)
    }

    public var last: Element? {
        let node = unsafe.head.previous
        if node !== unsafe.head {
            return node!.element
        }

        return nil
    }
}

extension LinkedList : RangeReplaceableCollection {

    public mutating func append(_ newElement: Element) {
        ensureUnique()
        attach(node: Node(newElement), after: unsafe.head.previous!)
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain = makeChain(newElements) {
            ensureUnique()
            attach(chain: chain, after: unsafe.head.previous!)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        failEarlyInsertionIndexCheck(i)

        var node = i.node
        ensureUnique(mark: &node)

        attach(node: Node(newElement), after: node.previous!)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        failEarlyInsertionIndexCheck(i)

        if let chain = makeChain(newElements) {
            var node = i.node
            ensureUnique(mark: &node)

            attach(chain: chain, after: node.previous!)
        }
    }

    public mutating func removeFirst() -> Element {
        ensureUnique()
        return abandon(node: unsafe.head.next!)
    }

    public mutating func removeLast() -> Element {
        ensureUnique()
        return abandon(node: unsafe.head.previous!)
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)

        var node = i.node
        ensureUnique(mark: &node)

        return abandon(node: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)

        var first = bounds.lowerBound.node
        var last = bounds.upperBound.node
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        abandon(after: first.previous!, before: last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        ensureUnique(skipAll: true)
        abandon(after: unsafe.head, before: unsafe.head)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        var first = subrange.lowerBound.node
        var last = subrange.upperBound.node
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        if let chain = makeChain(newElements) {
            attach(chain: chain, after: first.previous!, before: last)
        } else {
            abandon(after: first.previous!, before: last)
        }
    }
}
