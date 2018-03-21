//
//  DoublyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 13/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

// MARK: - LinkedListIterator

public struct LinkedListIterator<Element> : IteratorProtocol {
    private let uniqueness: AnyObject
    private var current: LinkedListNode<Element>?
    private let last: LinkedListNode<Element>?

    fileprivate init(uniqueness: AnyObject, first: LinkedListNode<Element>?, last: LinkedListNode<Element>?) {
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

// MARK: - LinkedListIndex

public struct LinkedListIndex<Element> : Comparable {
    unowned var identity: AnyObject
    var offset: Int
    var node: LinkedListNode<Element>

    public static func ==(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return lhs.node === rhs.node
    }

    public static func <(lhs: LinkedListIndex, rhs: LinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset && lhs.node !== rhs.node)
    }
}

// MARK: - UnsafeLinkedList

final class UnsafeLinkedList<Element> {
    var head: LinkedListNode<Element>

    init() {
        head = LinkedListNode()
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

    func makeClone(mark node: inout LinkedListNode<Element>) -> UnsafeLinkedList<Element> {
        let chain = LinkedListChain(head: head, tail: head.previous!)
        chain.tail.next = chain.head
        chain.head.previous = chain.tail

        return UnsafeLinkedList(head: chain.head)
    }

    func makeClone(skippingAfter first: inout LinkedListNode<Element>, skippingBefore last: inout LinkedListNode<Element>) -> UnsafeLinkedList<Element> {
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

// MARK: - LinkedList

public struct LinkedList<Element> {
    private var unsafe: UnsafeLinkedList<Element>

    public init() {
        unsafe = UnsafeLinkedList()
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
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.makeClone(mark: &node)
        }
    }

    private mutating func ensureUnique(skippingAfter first: inout Node, skippingBefore last: inout Node) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = unsafe.makeClone(skippingAfter: &first, skippingBefore: &last)
        }
    }

    private mutating func ensureUnique(skipAll: Bool) {
        if !isKnownUniquelyReferenced(&unsafe) {
            unsafe = UnsafeLinkedList()
        }
    }

    private func checkSelfIndex(_ index: Index) {
        precondition(index.identity === unsafe,
                     "Index does not belong to this linked list")
    }

    private func checkValidIndex(_ index: Index) {
        checkSelfIndex(index)
        precondition(index.node !== unsafe.head,
                     "Index is out of bounds")
    }

    private func checkNotEmpty() {
        precondition(!isEmpty,
                     "Linked list is empty")
    }

    private func checkValidRange(_ range: Range<Index>) {
        precondition(range.lowerBound.identity === unsafe,
                     "Range start index does not belong to this linked list")
        precondition(range.upperBound.identity === unsafe,
                     "Range end index does not belong to this linked list")
    }
}

// MARK: - Sequence

extension LinkedList : Sequence {
    public typealias Iterator = LinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return LinkedListIterator(uniqueness: unsafe,
                                  first: unsafe.head.next!,
                                  last: unsafe.head.previous!)
    }
}

// MARK: - LinkedCollection

extension LinkedList : LinkedCollection {
    public typealias Index = LinkedListIndex<Element>
    public typealias Node = LinkedListNode<Element>

    public var startIndex: Index {
        return Index(identity: unsafe, offset: 0, node: unsafe.head.next!)
    }

    public var endIndex: Index {
        return Index(identity: unsafe, offset: Int.max, node: unsafe.head)
    }

    public func index(after i: Index) -> Index {
        return Index(identity: i.identity,
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
        var node: Node! = start.node

        while node !== last {
            distance += 1
            node = node.next
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
        checkValidIndex(position)
        return position.node
    }
}

// MARK: - BidirectionalCollection

extension LinkedList : BidirectionalCollection {
    public func formIndex(before i: inout Index) {
        i.offset -= 1
        i.node = i.node.previous!
    }

    public func index(before i: Index) -> Index {
        return Index(identity: i.identity,
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

// MARK: - MutableCollection

extension LinkedList : MutableCollection {
    public subscript(position: Index) -> Element {
        get {
            checkValidIndex(position)
            return position.node.element
        }
        set(element) {
            checkSelfIndex(position)
            position.node.element = element
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            checkValidRange(bounds)
            return MutableRangeReplaceableBidirectionalSlice(base: self, bounds: bounds)
        }
    }

    public mutating func swapAt(_ i: Index, _ j: Index) {
        checkValidIndex(i)
        checkValidIndex(j)

        let first = i.node
        let second = j.node

        let temp = first.element
        first.element = second.element
        second.element = temp
    }
}

// MARK: - RangeReplaceableCollection

extension LinkedList : RangeReplaceableCollection {
    public mutating func append(_ newElement: Element) {
        ensureUnique()
        attach(node: Node(newElement), after: unsafe.head.previous!)
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain: LinkedListChain<Element> = makeChain(newElements) {
            ensureUnique()
            attach(chain: chain, after: unsafe.head.previous!)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        checkSelfIndex(i)

        var node = i.node
        ensureUnique(mark: &node)

        attach(node: Node(newElement), after: node.previous!)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        checkSelfIndex(i)

        if let chain: LinkedListChain<Element> = makeChain(newElements) {
            var node = i.node
            ensureUnique(mark: &node)

            attach(chain: chain, after: node.previous!)
        }
    }

    public mutating func removeFirst() -> Element {
        checkNotEmpty()
        ensureUnique()

        return abandon(node: unsafe.head.next!)
    }

    public mutating func removeLast() -> Element {
        checkNotEmpty()
        ensureUnique()

        return abandon(node: unsafe.head.previous!)
    }

    public mutating func remove(at i: Index) -> Element {
        checkValidIndex(i)
        checkNotEmpty()

        var node = i.node
        ensureUnique(mark: &node)

        return abandon(node: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        checkValidRange(bounds)

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
        checkValidRange(subrange)

        var first = subrange.lowerBound.node
        var last = subrange.upperBound.node
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        if let chain: LinkedListChain<Element> = makeChain(newElements) {
            attach(chain: chain, after: first.previous!, before: last)
        } else {
            abandon(after: first.previous!, before: last)
        }
    }
}
