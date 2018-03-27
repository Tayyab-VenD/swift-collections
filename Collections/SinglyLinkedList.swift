//
//  SinglyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

// MARK: - SinglyLinkedListIterator

public struct SinglyLinkedListIterator<Element> {
    private let owner: UnsafeForwardList<Element>
    private var node: UnsafeForwardNode<Element>!
    private let last: UnsafeForwardNode<Element>!

    init(owner: UnsafeForwardList<Element>,
         first: UnsafeForwardNode<Element>!,
         last: UnsafeForwardNode<Element>!) {
        self.owner = owner
        self.node = first
        self.last = last
    }
}

extension SinglyLinkedListIterator : IteratorProtocol {
    public mutating func next() -> Element? {
        if node != last {
            defer {
                node = node.next
            }
            return node.element!
        }

        return nil
    }
}

// MARK: - SinglyLinkedListIndex

public struct SinglyLinkedListIndex<Element> : Comparable {
    unowned(unsafe) var owner: UnsafeForwardList<Element>
    var tag: Int
    var previous: UnsafeForwardNode<Element>

    public static func ==(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return lhs.previous == rhs.previous
    }

    public static func <(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return lhs.tag < rhs.tag
    }
}

// MARK: - SinglyLinkedList

public struct SinglyLinkedList<Element> {
    private var unsafe: UnsafeForwardList<Element>

    public init() {
        unsafe = UnsafeForwardList()
    }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.init()
        append(contentsOf: elements)
    }

    @inline(__always)
    private mutating func ensureUnique() {
        var hmark = unsafe.head
        ensureUnique(marking: &hmark)
    }

    @inline(__always)
    private mutating func ensureUnique(marking node: inout UnsafeForwardNode<Element>) {
        var nmark = [node]
        ensureUnique(marking: &nmark)

        node = nmark[0]
    }

    private mutating func ensureUnique(marking nodes: inout [UnsafeForwardNode<Element>]) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.clone(marking: &nodes)
        }
    }

    private mutating func ensureUnique(skippingAfter first: inout UnsafeForwardNode<Element>,
                                       skippingBefore last: inout UnsafeForwardNode<Element>) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.clone(skippingAfter: &first, skippingBefore: &last)
        }
    }

    private func checkSelfIndex(_ index: Index) {
        precondition(index.owner === unsafe,
                     "Index does not belong to this linked list")
    }

    private func checkValidIndex(_ index: Index) {
        checkSelfIndex(index)
        precondition(index.previous != unsafe.tail,
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

extension SinglyLinkedList : Sequence {
    public typealias Iterator = SinglyLinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return SinglyLinkedListIterator(owner: unsafe,
                                        first: unsafe.head.next,
                                        last: unsafe.tail.next)
    }
}

// MARK: - LinkedCollection

extension SinglyLinkedList : LinkedCollection {
    public typealias Index = SinglyLinkedListIndex<Element>
    public typealias Node = SinglyLinkedListNode<Element>

    public var startIndex: Index {
        return Index(owner: unsafe, tag: 0, previous: unsafe.head)
    }

    public var endIndex: Index {
        return Index(owner: unsafe, tag: Int.max, previous: unsafe.tail)
    }

    public func index(after i: Index) -> Index {
        return Index(owner: i.owner,
                     tag: i.tag + 1,
                     previous: i.previous.next!)
    }

    public func formIndex(after i: inout Index) {
        i.tag += 1
        i.previous = i.previous.next!
    }

    public func distance(from start: Index, to end: Index) -> Int {
        var distance: Int = 0

        let last = end.previous.next
        var node = start.previous.next

        while node != last {
            distance += 1
            node = node!.next
        }

        return distance
    }

    public var count: Int {
        return distance(from: startIndex, to: endIndex)
    }

    public var isEmpty: Bool {
        return unsafe.tail == unsafe.head
    }

    public var first: Element? {
        return unsafe.head.next?.element
    }

    public func node(at position: Index) -> Node {
        checkValidIndex(position)
        return position.previous.next!.instance
    }
}

// MARK: - MutableCollection

extension SinglyLinkedList : MutableCollection {
    public subscript(position: Index) -> Element {
        get {
            checkValidIndex(position)
            return position.previous.next!.element
        }
        set(element) {
            checkSelfIndex(position)

            var last = position.previous
            ensureUnique(marking: &last)

            last.next!.element = element
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            checkValidRange(bounds)
            return MutableRangeReplaceableSlice(base: self, bounds: bounds)
        }
    }

    public mutating func swapAt(_ i: Index, _ j: Index) {
        checkValidIndex(i)
        checkValidIndex(j)

        var pair = [i.previous.next!, j.previous.next!]
        ensureUnique(marking: &pair)

        let temp = pair[0].element
        pair[0].element = pair[1].element
        pair[1].element = temp
    }
}

// MARK: - RangeReplaceableCollection

extension SinglyLinkedList : RangeReplaceableCollection {
    public mutating func append(_ newElement: Element) {
        ensureUnique()
        unsafe.attach(node: UnsafeForwardNode.make(newElement))
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain = UnsafeForwardChain.make(newElements) {
            ensureUnique()
            unsafe.attach(chain: chain)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        checkSelfIndex(i)

        var last = i.previous
        ensureUnique(marking: &last)

        unsafe.attach(node: UnsafeForwardNode.make(newElement), after: last)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        checkSelfIndex(i)

        if let chain = UnsafeForwardChain.make(newElements) {
            var last = i.previous
            ensureUnique(marking: &last)

            unsafe.attach(chain: chain, after: last)
        }
    }

    public mutating func removeFirst() -> Element {
        checkNotEmpty()
        ensureUnique()

        return unsafe.abandon(after: unsafe.head)
    }

    public mutating func remove(at i: Index) -> Element {
        checkValidIndex(i)
        checkNotEmpty()

        var node = i.previous
        ensureUnique(marking: &node)

        return unsafe.abandon(after: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        checkValidRange(bounds)

        var first = bounds.lowerBound.previous
        var last = bounds.upperBound.previous
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        unsafe.abandon(after: first, including: last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        var first = unsafe.head
        var last = unsafe.tail
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        unsafe.abandon(after: first, including: last)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        checkValidRange(subrange)

        var first = subrange.lowerBound.previous
        var last = subrange.upperBound.previous
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        if let chain = UnsafeForwardChain.make(newElements) {
            unsafe.attach(chain: chain, after: first, skipping: last)
        } else {
            unsafe.abandon(after: first, including: last)
        }
    }
}
