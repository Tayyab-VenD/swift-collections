//
//  SinglyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

fileprivate typealias Chain<Element> = (head: SinglyLinkedListNode<Element>, tail: SinglyLinkedListNode<Element>)

fileprivate func makeChain<S>(_ elements: S) -> Chain<S.Element>? where S : Sequence {
    // Proceed if collection contains at least one element.
    var iterator = elements.makeIterator()
    if let element = iterator.next() {
        // Create node for first element.
        var chain: Chain<S.Element>
        chain.head = SinglyLinkedListNode(element)
        chain.tail = chain.head

        // Create nodes for remaining elements.
        while let element = iterator.next() {
            let current = SinglyLinkedListNode(element)
            chain.tail.next = current
            chain.tail = current
        }

        return chain
    }

    return nil
}

fileprivate class Identity {
}

public class SinglyLinkedListNode<Element> {
    fileprivate var element: Element!
    fileprivate(set) public var next: SinglyLinkedListNode<Element>? = nil

    fileprivate init() {
    }

    init(_ element: Element!) {
        self.element = element
    }

    public var value: Element {
        return element!
    }
}

public struct SinglyLinkedListIterator<Element> : IteratorProtocol {
    private let uniqueness: Identity
    private var current: SinglyLinkedListNode<Element>?
    private let last: SinglyLinkedListNode<Element>?

    fileprivate init(uniqueness: Identity, first: SinglyLinkedListNode<Element>?, last: SinglyLinkedListNode<Element>?) {
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

public struct SinglyLinkedListIndex<Element> : Comparable {
    fileprivate var identity: Identity
    fileprivate var offset: Int
    fileprivate var previous: SinglyLinkedListNode<Element>

    public static func ==(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return lhs.offset == rhs.offset
    }

    public static func <(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset)
    }
}

public struct SinglyLinkedList<Element> {
    private var uniqueness: Identity // For ensuring copy-on-write
    private var identity: Identity   // For ensuring index validity
    private var offset: Int          // For slice index compatibility

    private var head: Node
    private var tail: Node

    public init() {
        uniqueness = Identity()
        identity = Identity()
        offset = 0
        head = Node()
        tail = head
    }

    private init(list: SinglyLinkedList<Element>, chain: (head: Node, tail: Node)) {
        uniqueness = list.uniqueness
        identity = list.identity
        offset = list.offset
        head = chain.head
        tail = chain.tail
    }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.init()
        append(contentsOf: elements)
    }

    private func failEarlyInsertionIndexCheck(_ index: Index) {
        precondition(index.identity === identity, "Invalid Index")
        // FIXME: Add Fatal Errors.
    }

    private func failEarlyRetrievalIndexCheck(_ index: Index) {
        precondition(index.identity === identity, "Invalid Index")
        precondition(index.previous !== tail, "Index out of bounds")
        // FIXME: Add Fatal Errors.
    }

    private func failEarlyRangeCheck(_ range: Range<Index>) {
        precondition(
            range.lowerBound.identity === identity && range.upperBound.identity === identity,
            "Invalid Range Bounds")
        // FIXME: Add Fatal Errors.
    }

    private mutating func makeMutableAndUnique() {
        if isKnownUniquelyReferenced(&uniqueness) {
            return
        }

        var chain: (head: Node, tail: Node)
        chain.head = Node()
        chain.tail = chain.head

        var node = head.next
        let last = tail.next

        // Make a new chain of all existing nodes.
        while node !== last {
            let current = Node(node?.element)
            chain.tail.next = current
            chain.tail = current

            node = node?.next
        }

        // Replace the bounding nodes.
        head = chain.head
        tail = chain.tail

        // Reset the state of list.
        uniqueness = Identity()
        identity = Identity()
    }

    private mutating func attach(node: Node) {
        attach(node: node, after: tail)
    }

    private mutating func attach(node: Node, after last: Node) {
        attach(chain: (head: node, tail: node), after: last)
    }

    private mutating func attach(chain: Chain<Element>) {
        attach(chain: chain, after: tail)
    }

    private mutating func attach(chain: Chain<Element>, after last: Node) {
        attach(chain: chain, after: last, skipping: last)
    }

    private mutating func attach(chain: Chain<Element>, after first: Node, skipping last: Node) {
        makeMutableAndUnique()

        let next = last.next    // In case `first` and `last` point to the same node.
        first.next = chain.head
        chain.tail.next = next

        if last === tail {
            tail = chain.tail
        }
    }

    private mutating func abandon(after node: Node) -> Element {
        let next = node.next!
        abandon(after: node, including: next)

        return next.element
    }

    private mutating func abandon(after first: Node, including last: Node) {
        makeMutableAndUnique()

        first.next = last.next

        if last === tail {
            tail = first
        }
    }
}

extension SinglyLinkedList : Sequence {
    public typealias Iterator = SinglyLinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return Iterator(uniqueness: uniqueness, first: head.next, last: tail.next)
    }
}

extension SinglyLinkedList : LinkedCollection {
    public typealias Index = SinglyLinkedListIndex<Element>
    public typealias Node = SinglyLinkedListNode<Element>
    public typealias SubSequence = SinglyLinkedList<Element>

    public var startIndex: Index {
        return Index(identity: identity, offset: 0, previous: head)
    }

    public var endIndex: Index {
        return Index(identity: identity, offset: Int.max, previous: tail)
    }

    public func index(after i: Index) -> Index {
        return Index(
            identity: i.identity,
            offset: i.offset + 1,
            previous: i.previous.next!)
    }

    public func formIndex(after i: inout Index) {
        i.offset += 1
        i.previous = i.previous.next!

        if i.previous === tail {
            i.offset = Int.max
        }
    }

    public func distance(from start: Index, to end: Index) -> Int {
        var distance: Int = 0

        let last = end.previous.next
        var node = start.previous.next

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
        return tail === head
    }

    public var first: Element? {
        return head.next?.element
    }

    public func node(at position: Index) -> Node {
        failEarlyRetrievalIndexCheck(position)
        return position.previous.next!
    }

    public subscript(position: Index) -> Element {
        get {
            failEarlyRetrievalIndexCheck(position)
            return position.previous.next!.element
        }
        set(element) {
            failEarlyInsertionIndexCheck(position)
            position.previous.next!.element = element
        }
    }

    public subscript(bounds: Range<Index>) -> SinglyLinkedList<Element> {
        get {
            failEarlyRangeCheck(bounds)

            let first = bounds.lowerBound.previous
            let last = bounds.upperBound.previous

            return SinglyLinkedList(list: self, chain: (head: first, tail: last))
        }
        set(slice) {
            failEarlyRangeCheck(bounds)

            let first = bounds.lowerBound.previous
            let last = bounds.upperBound.previous

            if !slice.isEmpty {
                // Slice has at least one element.
                let chain = (head: slice.head.next!, tail: slice.tail)
                attach(chain: chain, after: first, skipping: last)
            } else {
                // Slice has no element.
                abandon(after: first, including: last)
            }
        }
    }

    public mutating func swapAt(_ i: Index, _ j: Index) {
        failEarlyRetrievalIndexCheck(i)
        failEarlyRetrievalIndexCheck(j)

        let first = i.previous.next!
        let second = j.previous.next!

        let temp = first.element
        first.element = second.element
        second.element = temp
    }
}

extension SinglyLinkedList : RangeReplaceableCollection {

    public mutating func append(_ newElement: Element) {
        attach(node: Node(newElement))
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain = makeChain(newElements) {
            attach(chain: chain)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        failEarlyInsertionIndexCheck(i)
        attach(node: Node(newElement), after: i.previous)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        failEarlyInsertionIndexCheck(i)

        if let chain = makeChain(newElements) {
            attach(chain: chain, after: i.previous)
        }
    }

    public mutating func removeFirst() -> Element {
        // FIXME: Identity Checking...
        return abandon(after: head)
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)
        return abandon(after: i.previous)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)
        abandon(after: bounds.lowerBound.previous, including: bounds.upperBound.previous)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        abandon(after: head, including: tail)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        let first = subrange.lowerBound.previous
        let last = subrange.upperBound.previous

        if let chain = makeChain(newElements) {
            attach(chain: chain, after: first, skipping: last)
        } else {
            abandon(after: first, including: last)
        }
    }
}
