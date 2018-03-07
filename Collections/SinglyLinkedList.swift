//
//  SinglyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

fileprivate class Identity {
}

public class SinglyLinkedListNode<Element> {
    fileprivate var element: Element!
    fileprivate(set) var next: SinglyLinkedListNode<Element>? = nil

    fileprivate init() {
    }

    public init(_ element: Element) {
        self.element = element
    }

    public var value: Element {
        return element!
    }
}

public struct SinglyLinkedListIterator<Element> : IteratorProtocol {
    private var current: SinglyLinkedListNode<Element>?
    private let last: SinglyLinkedListNode<Element>?

    init(first: SinglyLinkedListNode<Element>?, last: SinglyLinkedListNode<Element>?) {
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
    private let identity = Identity()

    private var head: Node
    private var tail: Node

    public init() {
        head = Node()
        tail = head
    }

    private init(head: Node, tail: Node) {
        self.head = head
        self.tail = tail
    }

    private func failEarlyInsertionIndexCheck(_ index: Index) {
        // FIXME: Add Fatal Errors.
    }

    private func failEarlyRetrievalIndexCheck(_ index: Index) {
        // FIXME: Add Fatal Errors.
    }

    private func failEarlyRangeCheck(_ range: Range<Index>) {
        // FIXME: Add Fatal Errors.
    }

    public mutating func append(node: Node) {
        node.next = nil
        tail.next = node
        tail = node
    }

    public mutating func insert(node: Node, at i: Index) {
        failEarlyInsertionIndexCheck(i)
        attachAfter(i.previous, node: node)
    }

    private mutating func attachAfter(_ previous: Node, node: Node) {
        let next = previous.next
        previous.next = node
        node.next = next

        if previous === tail {
            tail = node
        }
    }

    private mutating func attachAfter(_ first: Node, skipping last: Node, chain: (head: Node, tail: Node)) {
        first.next = chain.head
        chain.tail.next = last.next

        if last === tail {
            tail = chain.tail
        }
    }

    private mutating func abandonNext(from first: Node, including last: Node) {
        first.next = last.next

        if last === tail {
            tail = first
        }
    }

    private mutating func abandonNext(of node: Node) -> Element {
        let current = node.next!
        node.next = current.next

        if current === tail {
            tail = node
        }

        return current.element
    }
}

extension SinglyLinkedList : Sequence {
    public typealias Iterator = SinglyLinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return Iterator(first: head.next, last: tail.next)
    }
}

extension SinglyLinkedList : Collection {
    public typealias Index = SinglyLinkedListIndex<Element>
    public typealias SubSequence = SinglyLinkedList<Element>

    public typealias Node = SinglyLinkedListNode<Element>

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
}

extension SinglyLinkedList : MutableCollection {

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
            return SinglyLinkedList(head: bounds.lowerBound.previous, tail: bounds.upperBound.previous)
        }
        set(slice) {
            failEarlyRangeCheck(bounds)

            let first = bounds.lowerBound.previous
            let last = bounds.upperBound.previous

            if slice.head !== slice.tail {
                // Slice has at least one element.
                let chain = (head: slice.head.next!, tail: slice.tail)
                attachAfter(first, skipping: last, chain: chain)
            } else {
                // Slice has no element.
                abandonNext(from: first, including: last)
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
        append(node: Node(newElement))
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        insert(node: Node(newElement), at: i)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        let first = subrange.lowerBound.previous
        let last = subrange.upperBound.previous

        // Proceed if there is at least one new element.
        var iterator = newElements.makeIterator()
        if let element = iterator.next() {
            // Create node for first element.
            var chain: (head: Node, tail: Node)
            chain.head = Node(element)
            chain.tail = chain.head

            // Create nodes for remaining elements.
            while let element = iterator.next() {
                let current = Node(element)
                chain.tail.next = current
                chain.tail = current
            }

            // Attach the specified subrange.
            attachAfter(first, skipping: last, chain: chain)
        } else {
            // Remove the specified subrange.
            abandonNext(from: first, including: last)
        }
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)
        return abandonNext(of: i.previous)
    }

    public mutating func removeFirst() -> Element {
        // FIXME: Identity Checking...
        return abandonNext(of: head)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)
        abandonNext(from: bounds.lowerBound.previous, including: bounds.upperBound.previous)
    }
}
