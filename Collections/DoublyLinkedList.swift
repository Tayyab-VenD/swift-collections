//
//  DoublyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 13/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

public struct LinkedListIterator<Element> : IteratorProtocol {
    private let owner: UnsafeList<Element>
    private var node: UnsafeNode<Element>
    private let last: UnsafeNode<Element>

    init(owner: UnsafeList<Element>,
         first: UnsafeNode<Element>,
         last: UnsafeNode<Element>) {
        self.owner = owner
        self.node = first
        self.last = last
    }

    public mutating func next() -> Element? {
        if node != last {
            defer {
                node = node.next
            }
            return node.element
        }

        return nil
    }
}

public struct LinkedListIndex<Element> : Comparable {
    unowned(unsafe) var owner: UnsafeList<Element>
    var tag: Int
    var node: UnsafeNode<Element>

    public static func ==(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return lhs.node == rhs.node
    }

    public static func <(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return lhs.tag < rhs.tag
    }
}

public struct LinkedList<Element> {
    private var unsafe: UnsafeList<Element>

    public init() {
        unsafe = UnsafeList()
    }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.init()
        append(contentsOf: elements)
    }

    @inline(__always)
    private mutating func ensureUnique() {
        var emark: [UnsafeNode<Element>] = []
        ensureUnique(marking: &emark)
    }

    @inline(__always)
    private mutating func ensureUnique(marking node: inout UnsafeNode<Element>) {
        var nmark = [node]
        ensureUnique(marking: &nmark)

        node = nmark[0]
    }

    private mutating func ensureUnique(marking nodes: inout [UnsafeNode<Element>]) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.clone(marking: &nodes)
        }
    }

    private mutating func ensureUnique(skippingAfter first: inout UnsafeNode<Element>,
                                       skippingBefore last: inout UnsafeNode<Element>) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.clone(skippingAfter: &first, skippingBefore: &last)
        }
    }

    private mutating func ensureUnique(skippingAll: Bool) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = UnsafeList()
        }
    }

    private func checkSelfIndex(_ index: Index) {
        precondition(index.owner === unsafe,
                     "Index does not belong to this linked list")
    }

    private func checkValidIndex(_ index: Index) {
        checkSelfIndex(index)
        precondition(index.node != unsafe.head,
                     "Index is out of bounds")
    }

    private func checkNotEmpty() {
        precondition(!isEmpty,
                     "Linked list is empty")
    }

    private func checkValidRange(_ range: Range<Index>) {
        precondition(range.lowerBound.owner === unsafe,
                     "Range start index does not belong to this linked list")
        precondition(range.upperBound.owner === unsafe,
                     "Range end index does not belong to this linked list")
    }
}

// MARK: - Sequence

extension LinkedList : Sequence {
    public typealias Iterator = LinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return LinkedListIterator(owner: unsafe,
                                  first: unsafe.head.next,
                                  last: unsafe.head.previous)
    }
}

// MARK: - LinkedCollection

extension LinkedList : LinkedCollection {
    public typealias Index = LinkedListIndex<Element>
    public typealias Node = LinkedListNode<Element>

    public var startIndex: Index {
        return Index(owner: unsafe, tag: 0, node: unsafe.head.next)
    }

    public var endIndex: Index {
        return Index(owner: unsafe, tag: Int.max, node: unsafe.head)
    }

    public func index(after i: Index) -> Index {
        return Index(owner: i.owner,
                     tag: i.tag + 1,
                     node: i.node.next)
    }

    public func formIndex(after i: inout Index) {
        i.tag += 1
        i.node = i.node.next
    }

    public func distance(from start: Index, to end: Index) -> Int {
        var distance: Int = 0

        let last = end.node
        var node = start.node

        while node != last {
            distance += 1
            node = node.next
        }

        return distance
    }

    public var count: Int {
        return distance(from: startIndex, to: endIndex)
    }

    public var isEmpty: Bool {
        return unsafe.head == unsafe.head.next
    }

    public var first: Element? {
        let node = unsafe.head.next
        if node != unsafe.head {
            return node.element
        }

        return nil
    }

    public func node(at position: Index) -> Node {
        checkValidIndex(position)
        return position.node.instance
    }
}

// MARK: - BidirectionalCollection

extension LinkedList : BidirectionalCollection {
    public func formIndex(before i: inout Index) {
        i.tag -= 1
        i.node = i.node.previous
    }

    public func index(before i: Index) -> Index {
        return Index(owner: i.owner,
                     tag: i.tag - 1,
                     node: i.node.previous)
    }

    public var last: Element? {
        let node = unsafe.head.previous
        if node != unsafe.head {
            return node.element
        }

        return nil
    }
}

// MARK: - MutableCollection

extension LinkedList : MutableCollection {
    public subscript(position: Index) -> Element {
        get {
            checkValidIndex(position)
            return position.node.element
        }
        set(element) {
            checkSelfIndex(position)

            var node = position.node
            ensureUnique(marking: &node)

            node.element = element
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            checkValidRange(bounds)
            return MutableRangeReplaceableBidirectionalSlice(base: self, bounds: bounds)
        }
        set(slice) {
            replaceSubrange(bounds, with: slice)
        }
    }

    public mutating func swapAt(_ i: Index, _ j: Index) {
        checkValidIndex(i)
        checkValidIndex(j)

        var pair = [i.node, j.node]
        ensureUnique(marking: &pair)

        let temp = pair[0].element
        pair[0].element = pair[1].element
        pair[1].element = temp
    }
}

// MARK: - RangeReplaceableCollection

extension LinkedList : RangeReplaceableCollection {
    public mutating func append(_ newElement: Element) {
        ensureUnique()
        unsafe.attach(node: UnsafeNode.make(newElement), after: unsafe.head.previous)
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain = UnsafeChain.make(newElements) {
            ensureUnique()
            unsafe.attach(chain: chain, after: unsafe.head.previous)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        checkSelfIndex(i)

        var node = i.node
        ensureUnique(marking: &node)

        unsafe.attach(node: UnsafeNode.make(newElement), after: node.previous)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        checkSelfIndex(i)

        if let chain = UnsafeChain.make(newElements) {
            var node = i.node
            ensureUnique(marking: &node)

            unsafe.attach(chain: chain, after: node.previous)
        }
    }

    public mutating func removeFirst() -> Element {
        checkNotEmpty()
        ensureUnique()

        return unsafe.abandon(node: unsafe.head.next)
    }

    public mutating func removeLast() -> Element {
        checkNotEmpty()
        ensureUnique()

        return unsafe.abandon(node: unsafe.head.previous)
    }

    public mutating func remove(at i: Index) -> Element {
        checkValidIndex(i)
        checkNotEmpty()

        var node = i.node
        ensureUnique(marking: &node)

        return unsafe.abandon(node: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        checkValidRange(bounds)

        var first = bounds.lowerBound.node
        var last = bounds.upperBound.node
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        unsafe.abandon(after: first.previous, before: last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        ensureUnique(skippingAll: true)
        unsafe.abandon(after: unsafe.head, before: unsafe.head)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        checkValidRange(subrange)

        var first = subrange.lowerBound.node
        var last = subrange.upperBound.node
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        if let chain = UnsafeChain.make(newElements) {
            unsafe.attach(chain: chain, after: first.previous, before: last)
        } else {
            unsafe.abandon(after: first.previous, before: last)
        }
    }
}
