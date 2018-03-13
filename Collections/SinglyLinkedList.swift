//
//  SinglyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

typealias Node<Element> = SinglyLinkedListNode<Element>
typealias Chain<Element> = (head: SinglyLinkedListNode<Element>, tail: SinglyLinkedListNode<Element>)

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

fileprivate func cloneChain<Element>(first: SinglyLinkedListNode<Element>, last: SinglyLinkedListNode<Element>) -> Chain<Element> {
    // Clone first node.
    var chain: Chain<Element>
    chain.head = SinglyLinkedListNode(first.element)
    chain.tail = chain.head

    var node = first.next
    let limit = last.next

    // Clone remaining nodes.
    while node !== limit {
        let clone = SinglyLinkedListNode(node!.element)
        chain.tail.next = clone
        chain.tail = clone

        node = node!.next
    }

    return chain
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
    private let uniqueness: AnyObject
    private var current: SinglyLinkedListNode<Element>?
    private let last: SinglyLinkedListNode<Element>?

    fileprivate init(uniqueness: AnyObject, first: SinglyLinkedListNode<Element>?, last: SinglyLinkedListNode<Element>?) {
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
    fileprivate unowned var identity: Identity
    fileprivate var offset: Int
    fileprivate var previous: SinglyLinkedListNode<Element>

    public static func ==(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return lhs.previous === rhs.previous
    }

    public static func <(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset && lhs.previous !== rhs.previous)
    }
}

class UnsafeSinglyLinkedList<Element> {
    fileprivate var identity = Identity()  // For ensuring index validity

    var head: Node<Element>
    var tail: Node<Element>

    init() {
        head = Node()
        tail = head
    }

    private init(head: Node<Element>, tail: Node<Element>) {
        self.head = head
        self.tail = tail
    }

    func makeClone() -> UnsafeSinglyLinkedList<Element> {
        let clonedChain = cloneChain(first: head, last: tail)
        return UnsafeSinglyLinkedList(head: clonedChain.head, tail: clonedChain.tail)
    }

    func makeCloneSkippingInners(first: inout Node<Element>, last: inout Node<Element>) -> UnsafeSinglyLinkedList<Element> {
        let leadingChain = cloneChain(first: head, last: first)
        var trailingHead: Node<Element>? = nil
        var clonedTail = leadingChain.tail

        if let next = first !== last ? last : last.next {
            let trailingChain = cloneChain(first: next, last: tail)
            leadingChain.tail.next = trailingChain.head

            trailingHead = trailingChain.head
            clonedTail = trailingChain.tail
        }

        last = first !== last ? trailingHead! : leadingChain.tail
        first = leadingChain.tail

        return UnsafeSinglyLinkedList(head: leadingChain.head, tail: clonedTail)
    }

    func attach(node: Node<Element>) {
        attach(node: node, after: tail)
    }

    func attach(node: Node<Element>, after last: Node<Element>) {
        attach(chain: (head: node, tail: node), after: last)
    }

    func attach(chain: Chain<Element>) {
        attach(chain: chain, after: tail)
    }

    func attach(chain: Chain<Element>, after last: Node<Element>) {
        attach(chain: chain, after: last, skipping: last)
    }

    func attach(chain: Chain<Element>, after first: Node<Element>, skipping last: Node<Element>) {
        let next = last.next    // In case `first` and `last` point to the same node.
        first.next = chain.head
        chain.tail.next = next

        if last === tail {
            tail = chain.tail
        }
    }

    func abandon(after node: Node<Element>) -> Element {
        let next = node.next!
        abandon(after: node, including: next)

        return next.element
    }

    func abandon(after first: Node<Element>, including last: Node<Element>) {
        first.next = last.next

        if last === tail {
            tail = first
        }
    }
}

public struct SinglyLinkedList<Element> {
    private var unsafe: UnsafeSinglyLinkedList<Element>
    private var range: Range<Index>? // For slice index compatibility

    public init() {
        unsafe = UnsafeSinglyLinkedList()
    }

    private init(list: SinglyLinkedList<Element>, bounds: Range<Index>) {
        range = bounds
        unsafe = list.unsafe
    }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        self.init()
        append(contentsOf: elements)
    }

    private mutating func ensureUniqueBox() {
        if isKnownUniquelyReferenced(&unsafe) {
            return
        }

        unsafe = unsafe.makeClone()
    }

    private mutating func ensureUniqueWithMark(_ node: inout Node) {
        var last = node
        ensureUniqueSkippingInners(&node, &last)
    }

    private mutating func ensureUniqueSkippingInners(_ first: inout Node, _ last: inout Node) {
        if isKnownUniquelyReferenced(&unsafe) {
            return
        }

        unsafe = unsafe.makeCloneSkippingInners(first: &first, last: &last)
    }

    private func failEarlyInsertionIndexCheck(_ index: Index) {
        precondition(index.identity === unsafe.identity, "Invalid Index")
    }

    private func failEarlyRetrievalIndexCheck(_ index: Index) {
        precondition(index.identity === unsafe.identity, "Invalid Index")
        precondition(index.previous !== unsafe.tail, "Index out of bounds")
    }

    private func failEarlyRangeCheck(_ range: Range<Index>) {
        precondition(
            range.lowerBound.identity === unsafe.identity && range.upperBound.identity === unsafe.identity,
            "Invalid Range Bounds")
    }
}

extension SinglyLinkedList : Sequence {
    public typealias Iterator = SinglyLinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return Iterator(uniqueness: unsafe, first: unsafe.head.next, last: unsafe.tail.next)
    }
}

extension SinglyLinkedList : LinkedCollection {
    public typealias Index = SinglyLinkedListIndex<Element>
    public typealias Node = SinglyLinkedListNode<Element>
    public typealias SubSequence = SinglyLinkedList<Element>

    public var startIndex: Index {
        if range == nil {
            return Index(identity: unsafe.identity, offset: 0, previous: unsafe.head)
        }

        return range!.lowerBound
    }

    public var endIndex: Index {
        if range == nil {
            return Index(identity: unsafe.identity, offset: Int.max, previous: unsafe.tail)
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
        return unsafe.tail === unsafe.head
    }

    public var first: Element? {
        return unsafe.head.next?.element
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
            ensureUniqueSkippingInners(&first, &last)

            if !slice.isEmpty {
                // Slice has at least one element.
                let chain = (head: slice.unsafe.head.next!, tail: slice.unsafe.tail)
                unsafe.attach(chain: chain, after: first, skipping: last)
            } else {
                // Slice has no element.
                unsafe.abandon(after: first, including: last)
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
        ensureUniqueBox()
        unsafe.attach(node: Node(newElement))
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain = makeChain(newElements) {
            ensureUniqueBox()
            unsafe.attach(chain: chain)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        failEarlyInsertionIndexCheck(i)

        var last = i.previous
        ensureUniqueWithMark(&last)

        unsafe.attach(node: Node(newElement), after: last)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        failEarlyInsertionIndexCheck(i)

        if let chain = makeChain(newElements) {
            var last = i.previous
            ensureUniqueWithMark(&last)

            unsafe.attach(chain: chain, after: last)
        }
    }

    public mutating func removeFirst() -> Element {
        ensureUniqueBox()
        return unsafe.abandon(after: unsafe.head)
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)

        var node = i.previous
        ensureUniqueWithMark(&node)

        return unsafe.abandon(after: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)

        var first = bounds.lowerBound.previous
        var last = bounds.upperBound.previous
        ensureUniqueSkippingInners(&first, &last)

        unsafe.abandon(after: first, including: last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        var first = unsafe.head
        var last = unsafe.tail
        ensureUniqueSkippingInners(&first, &last)

        unsafe.abandon(after: first, including: last)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        var first = subrange.lowerBound.previous
        var last = subrange.upperBound.previous
        ensureUniqueSkippingInners(&first, &last)

        if let chain = makeChain(newElements) {
            unsafe.attach(chain: chain, after: first, skipping: last)
        } else {
            unsafe.abandon(after: first, including: last)
        }
    }
}
