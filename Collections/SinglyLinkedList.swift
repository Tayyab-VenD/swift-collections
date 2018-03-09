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
        return lhs.previous === rhs.previous
    }

    public static func <(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset)
    }
}

public struct SinglyLinkedList<Element> {
    private var uniqueness: Identity // For ensuring copy-on-write
    private var identity: Identity   // For ensuring index validity
    private var range: Range<Index>? // For slice index compatibility

    private var head: Node
    private var tail: Node

    public init() {
        uniqueness = Identity()
        identity = Identity()
        head = Node()
        tail = head
    }

    private init(list: SinglyLinkedList<Element>, bounds: Range<Index>) {
        uniqueness = list.uniqueness
        identity = list.identity
        range = bounds
        head = bounds.lowerBound.previous
        tail = bounds.upperBound.previous
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

    private mutating func makeMutableAndUnique(first: inout Node, last: inout Node) {
        if isKnownUniquelyReferenced(&uniqueness) {
            return
        }

        var chain: Chain<Element>
        chain.head = Node()
        chain.tail = chain.head

        var node = head.next
        let limit = tail.next

        // Make a new chain of all existing nodes.
        while node !== limit {
            let current = Node(node?.element)
            chain.tail.next = current
            chain.tail = current

            if node === first {
                first = current
            }
            if node === last {
                last = current
            }

            node = node?.next
        }

        // Replace the bounding nodes.
        head = chain.head
        tail = chain.tail

        // Reset the state of list.
        uniqueness = Identity()
        identity = Identity()
        range = nil
    }

    private mutating func attach(node: Node) {
        var last = tail
        attach(node: node, after: &last)
    }

    private mutating func attach(node: Node, after last: inout Node) {
        attach(chain: (head: node, tail: node), after: &last)
    }

    private mutating func attach(chain: Chain<Element>) {
        var last = tail
        attach(chain: chain, after: &last)
    }

    private mutating func attach(chain: Chain<Element>, after last: inout Node) {
        var first = last
        attach(chain: chain, after: &first, skipping: &last)
    }

    private mutating func attach(chain: Chain<Element>, after first: inout Node, skipping last: inout Node) {
        makeMutableAndUnique(first: &first, last: &last)

        let next = last.next    // In case `first` and `last` point to the same node.
        first.next = chain.head
        chain.tail.next = next

        if last === tail {
            tail = chain.tail
        }
    }

    private mutating func abandon(after node: inout Node) -> Element {
        var next = node.next!
        abandon(after: &node, including: &next)

        return next.element
    }

    private mutating func abandon(after first: inout Node, including last: inout Node) {
        makeMutableAndUnique(first: &first, last: &last)

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
        if range == nil {
            return Index(identity: identity, offset: 0, previous: head)
        }

        return range!.lowerBound
    }

    public var endIndex: Index {
        if range == nil {
            return Index(identity: identity, offset: Int.max, previous: tail)
        }

        return range!.upperBound
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
            return SinglyLinkedList(list: self, bounds: bounds)
        }
        set(slice) {
            failEarlyRangeCheck(bounds)

            var first = bounds.lowerBound.previous
            var last = bounds.upperBound.previous

            if !slice.isEmpty {
                // Slice has at least one element.
                let chain = (head: slice.head.next!, tail: slice.tail)
                attach(chain: chain, after: &first, skipping: &last)
            } else {
                // Slice has no element.
                abandon(after: &first, including: &last)
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

        var node = i.previous
        attach(node: Node(newElement), after: &node)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        failEarlyInsertionIndexCheck(i)

        if let chain = makeChain(newElements) {
            var node = i.previous
            attach(chain: chain, after: &node)
        }
    }

    public mutating func removeFirst() -> Element {
        // FIXME: Identity Checking...
        var node = head
        return abandon(after: &node)
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)

        var node = i.previous
        return abandon(after: &node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)

        var first = bounds.lowerBound.previous
        var last = bounds.upperBound.previous

        abandon(after: &first, including: &last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        var first = head
        var last = tail

        abandon(after: &first, including: &last)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        var first = subrange.lowerBound.previous
        var last = subrange.upperBound.previous

        if let chain = makeChain(newElements) {
            attach(chain: chain, after: &first, skipping: &last)
        } else {
            abandon(after: &first, including: &last)
        }
    }
}
