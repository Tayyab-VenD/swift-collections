//
//  SinglyLinkedList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

// MARK: - SinglyLinkedListIterator

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

// MARK: - SinglyLinkedListIndex

public struct SinglyLinkedListIndex<Element> : Comparable {
    unowned var identity: AnyObject
    var offset: Int
    var previous: SinglyLinkedListNode<Element>

    public static func ==(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return lhs.previous === rhs.previous
    }

    public static func <(lhs: SinglyLinkedListIndex, rhs: SinglyLinkedListIndex) -> Bool {
        return (lhs.offset < rhs.offset && lhs.previous !== rhs.previous)
    }
}

// MARK: - UnsafeSinglyLinkedList

final class UnsafeSinglyLinkedList<Element> {
    var head: SinglyLinkedListNode<Element>
    var tail: SinglyLinkedListNode<Element>

    init() {
        head = SinglyLinkedListNode()
        tail = head
    }

    private init(chain: SinglyLinkedListChain<Element>) {
        self.head = chain.head
        self.tail = chain.tail
    }

    private init(head: SinglyLinkedListNode<Element>, tail: SinglyLinkedListNode<Element>) {
        self.head = head
        self.tail = tail
    }

    func makeClone(mark node: inout SinglyLinkedListNode<Element>) -> UnsafeSinglyLinkedList<Element> {
        let chain = SinglyLinkedListChain(head: head, tail: tail)
        let clone = cloneChain(chain, mark: &node)
        return UnsafeSinglyLinkedList(head: clone.head, tail: clone.tail)
    }

    func makeClone(skippingAfter first: inout SinglyLinkedListNode<Element>, skippingBefore last: inout SinglyLinkedListNode<Element>) -> UnsafeSinglyLinkedList<Element> {
        guard first !== last else {
            let clone = makeClone(mark: &first)
            last = first

            return clone
        }

        let leadingChain = cloneChain(SinglyLinkedListChain(head: head, tail: first), mark: &first)
        let trailingChain = cloneChain(SinglyLinkedListChain(head: last, tail: tail), mark: &last)

        // Attach leading and trailing chains.
        leadingChain.tail.next = trailingChain.head

        return UnsafeSinglyLinkedList(head: leadingChain.head, tail: trailingChain.tail)
    }
}

// MARK: - SinglyLinkedList

public struct SinglyLinkedList<Element> {
    private var unsafe: UnsafeSinglyLinkedList<Element>

    public init() {
        unsafe = UnsafeSinglyLinkedList()
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

    private func checkSelfIndex(_ index: Index) {
        precondition(index.identity === unsafe,
                     "Index does not belong to this linked list")
    }

    private func checkValidIndex(_ index: Index) {
        checkSelfIndex(index)
        precondition(index.previous !== unsafe.tail,
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

extension SinglyLinkedList : Sequence {
    public typealias Iterator = SinglyLinkedListIterator<Element>

    public func makeIterator() -> Iterator {
        return SinglyLinkedListIterator(uniqueness: unsafe,
                                        first: unsafe.head.next,
                                        last: unsafe.tail.next)
    }
}

// MARK: - LinkedCollection

extension SinglyLinkedList : LinkedCollection {
    public typealias Index = SinglyLinkedListIndex<Element>
    public typealias Node = SinglyLinkedListNode<Element>

    public var startIndex: Index {
        return Index(identity: unsafe, offset: 0, previous: unsafe.head)
    }

    public var endIndex: Index {
        return Index(identity: unsafe, offset: Int.max, previous: unsafe.tail)
    }

    public func index(after i: Index) -> Index {
        return Index(identity: i.identity,
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
            node = node!.next
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
        checkValidIndex(position)
        return position.previous.next!
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
            position.previous.next!.element = element
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

        let first = i.previous.next!
        let second = j.previous.next!

        let temp = first.element
        first.element = second.element
        second.element = temp
    }
}

// MARK: - RangeReplaceableCollection

extension SinglyLinkedList : RangeReplaceableCollection {

    public mutating func append(_ newElement: Element) {
        ensureUnique()
        attach(node: Node(newElement), after: &unsafe.tail)
    }

    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        if let chain: SinglyLinkedListChain<Element> = makeChain(newElements) {
            ensureUnique()
            attach(chain: chain, after: &unsafe.tail)
        }
    }

    public mutating func insert(_ newElement: Element, at i: Index) {
        checkSelfIndex(i)

        var last = i.previous
        ensureUnique(mark: &last)

        attach(node: Node(newElement), after: last, revise: &unsafe.tail)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: Index) where S : Collection, Element == S.Element {
        checkSelfIndex(i)

        if let chain: SinglyLinkedListChain<Element> = makeChain(newElements) {
            var last = i.previous
            ensureUnique(mark: &last)

            attach(chain: chain, after: last, revise: &unsafe.tail)
        }
    }

    public mutating func removeFirst() -> Element {
        checkNotEmpty()
        ensureUnique()

        return abandon(after: unsafe.head, revise: &unsafe.tail)
    }

    public mutating func remove(at i: Index) -> Element {
        checkValidIndex(i)
        checkNotEmpty()

        var node = i.previous
        ensureUnique(mark: &node)

        return abandon(after: node, revise: &unsafe.tail)
    }

    public mutating func removeSubrange(_ bounds: Range<Index>) {
        checkValidRange(bounds)

        var first = bounds.lowerBound.previous
        var last = bounds.upperBound.previous
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        abandon(after: first, including: last, revise: &unsafe.tail)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        var first = unsafe.head
        var last = unsafe.tail
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        abandon(after: first, including: last, revise: &unsafe.tail)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        checkValidRange(subrange)

        var first = subrange.lowerBound.previous
        var last = subrange.upperBound.previous
        ensureUnique(skippingAfter: &first, skippingBefore: &last)

        if let chain: SinglyLinkedListChain<Element> = makeChain(newElements) {
            attach(chain: chain, after: first, skipping: last, revise: &unsafe.tail)
        } else {
            abandon(after: first, including: last, revise: &unsafe.tail)
        }
    }
}
