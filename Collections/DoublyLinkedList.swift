//
//  DoublyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 13/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

fileprivate typealias Node<Element> = LinkedListNode<Element>
fileprivate typealias Chain<Element> = (head: Node<Element>, tail: Node<Element>)

fileprivate func makeChain<S>(_ elements: S) -> Chain<S.Element>? where S : Sequence {
    // Proceed if collection contains at least one element.
    var iterator = elements.makeIterator()
    if let element = iterator.next() {
        // Create node for first element.
        var chain: Chain<S.Element>
        chain.head = Node(element)
        chain.tail = chain.head

        // Create nodes for remaining elements.
        while let element = iterator.next() {
            let current = Node(element)
            current.previous = chain.tail
            chain.tail.next = current
            chain.tail = current
        }

        return chain
    }

    return nil
}

fileprivate func cloneChain<Element>(first: Node<Element>, last: Node<Element>) -> Chain<Element> {
    // Clone first node.
    var chain: Chain<Element>
    chain.head = Node(first.element)
    chain.tail = chain.head

    var node = first.next
    let limit = last.next

    // Clone remaining nodes.
    while node !== limit {
        let clone = Node(node!.element)
        clone.previous = chain.tail
        chain.tail.next = clone
        chain.tail = clone

        node = node!.next
    }

    return chain
}

public final class LinkedListNode<Element> {
    fileprivate(set) var element: Element!
    fileprivate(set) public var next: LinkedListNode<Element>? = nil
    fileprivate(set) public weak var previous: LinkedListNode<Element>? = nil

    fileprivate init() {
    }

    init(_ element: Element!) {
        self.element = element
    }

    public var value: Element {
        return element!
    }
}

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

    private init(head: Node<Element>, tail: Node<Element>) {
        self.head = head
    }

    func makeClone() -> UnsafeLinkedList<Element> {
        let clonedChain = cloneChain(first: head, last: head)
        return UnsafeLinkedList(head: clonedChain.head, tail: clonedChain.tail)
    }

    func makeCloneSkippingInners(first: inout Node<Element>, last: inout Node<Element>) -> UnsafeLinkedList<Element> {
        let leadingChain = cloneChain(first: head, last: first)
        var trailingHead: Node<Element>? = nil
        var clonedTail = leadingChain.tail

        if let next = first !== last ? last : last.next {
            let trailingChain = cloneChain(first: next, last: head)
            trailingChain.head.previous = leadingChain.tail
            leadingChain.tail.next = trailingChain.head

            trailingHead = trailingChain.head
            clonedTail = trailingChain.tail
        }

        last = first !== last ? trailingHead! : leadingChain.tail
        first = leadingChain.tail

        return UnsafeLinkedList(head: leadingChain.head, tail: clonedTail)
    }

    func attach(node: Node<Element>) {
        attach(node: node, after: head.previous!)
    }

    func attach(node: Node<Element>, after target: Node<Element>) {
        attach(node: node, after: target, before: target.next!)
    }

    func attach(node: Node<Element>, after first: Node<Element>, before last: Node<Element>) {
        last.previous = node
        node.next = last
        node.previous = first
        first.next = node
    }

    func attach(chain: Chain<Element>) {
        attach(chain: chain, after: head.previous!)
    }

    func attach(chain: Chain<Element>, after target: Node<Element>) {
        attach(chain: chain, after: target, before: target.next!)
    }

    func attach(chain: Chain<Element>, after first: Node<Element>, before last:Node<Element>) {
        last.previous = chain.tail
        chain.tail.next = last
        chain.head.previous = first
        first.next = chain.head
    }

    func abandon(node: Node<Element>) -> Element {
        abandon(after: node.previous!, before: node.next!)
        return node.element
    }

    func abandon(after first: Node<Element>, before last: Node<Element>) {
        last.previous = first
        first.next = last
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
            ensureUniqueSkippingInners(&first, &last)

            if !slice.isEmpty {
                // Slice has at least one element.
                let chain = (head: slice.unsafe.head.next!, tail: slice.unsafe.head.previous!)
                unsafe.attach(chain: chain, after: first.previous!, before: last)
            } else {
                // Slice has no element.
                unsafe.abandon(after: first.previous!, before: last)
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

        var node = i.node
        ensureUniqueWithMark(&node)

        unsafe.attach(node: Node(newElement), after: node.previous!)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        failEarlyInsertionIndexCheck(i)

        if let chain = makeChain(newElements) {
            var node = i.node
            ensureUniqueWithMark(&node)

            unsafe.attach(chain: chain, after: node.previous!)
        }
    }

    public mutating func removeFirst() -> Element {
        ensureUniqueBox()
        return unsafe.abandon(node: unsafe.head.next!)
    }

    public mutating func removeLast() -> Element {
        ensureUniqueBox()
        return unsafe.abandon(node: unsafe.head.previous!)
    }

    public mutating func remove(at i: Index) -> Element {
        failEarlyRetrievalIndexCheck(i)

        var node = i.node
        ensureUniqueWithMark(&node)

        return unsafe.abandon(node: node)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        failEarlyRangeCheck(bounds)

        var first = bounds.lowerBound.node
        var last = bounds.upperBound.node
        ensureUniqueSkippingInners(&first, &last)

        unsafe.abandon(after: first.previous!, before: last)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        var first = unsafe.head
        var last = unsafe.head
        ensureUniqueSkippingInners(&first, &last)

        unsafe.abandon(after: first, before: last)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        failEarlyRangeCheck(subrange)

        var first = subrange.lowerBound.node
        var last = subrange.upperBound.node
        ensureUniqueSkippingInners(&first, &last)

        if let chain = makeChain(newElements) {
            unsafe.attach(chain: chain, after: first.previous!, before: last)
        } else {
            unsafe.abandon(after: first.previous!, before: last)
        }
    }
}
