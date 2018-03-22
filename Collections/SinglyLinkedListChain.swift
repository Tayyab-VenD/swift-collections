//
//  SinglyLinkedListChain.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 19/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

struct SinglyLinkedListChain<Element> {
    unowned(unsafe) var head: SinglyLinkedListNode<Element>
    unowned(unsafe) var tail: SinglyLinkedListNode<Element>
}

public final class SinglyLinkedListNode<Element> {
    var element: Element!
    var unext: Unmanaged<SinglyLinkedListNode<Element>>?

    public var next: SinglyLinkedListNode<Element>? {
        return unext?.takeUnretainedValue()
    }

    @inline(__always)
    static func makeRetained(_ element: Element! = nil) -> SinglyLinkedListNode<Element> {
        return SinglyLinkedListNode<Element>(element).retain()
    }

    private init(_ element: Element!) {
        self.element = element
    }

    @inline(__always)
    func unmanaged() -> Unmanaged<SinglyLinkedListNode<Element>> {
        return Unmanaged.passUnretained(self)
    }

    @inline(__always)
    func retain() -> SinglyLinkedListNode<Element> {
        let _ = Unmanaged.passRetained(self)
        return self
    }

    @inline(__always)
    func release() {
        unext = nil
        Unmanaged.passUnretained(self).release()
    }

    public var value: Element {
        return element!
    }
}

func makeChain<S>(_ elements: S) -> SinglyLinkedListChain<S.Element>? where S : Sequence {
    // Proceed if collection contains at least one element.
    var iterator = elements.makeIterator()
    if let element = iterator.next() {
        // Create node for first element and initialize the chain.
        unowned(unsafe) let first = SinglyLinkedListNode.makeRetained(element)
        var chain = SinglyLinkedListChain(head: first, tail: first)

        // Create nodes for remaining elements.
        while let element = iterator.next() {
            unowned(unsafe) let current = SinglyLinkedListNode.makeRetained(element)
            chain.tail.unext = current.unmanaged()
            chain.tail = current
        }

        return chain
    }

    return nil
}

func cloneChain<E>(_ chain: SinglyLinkedListChain<E>, mark: inout SinglyLinkedListNode<E>) -> SinglyLinkedListChain<E> {
    // Clone first node.
    unowned(unsafe) let head = SinglyLinkedListNode.makeRetained(chain.head.element)
    unowned(unsafe) var tail = head

    if mark === chain.head {
        mark = head
    }

    var node = chain.head.next
    let limit = chain.tail.next

    // Clone remaining nodes.
    while node !== limit {
        unowned(unsafe) let clone = SinglyLinkedListNode.makeRetained(node!.element)
        tail.unext = clone.unmanaged()
        tail = clone

        if node === mark {
            mark = clone
        }

        node = node!.next
    }

    return SinglyLinkedListChain(head: head, tail: tail)
}

func releaseChain<E>(_ chain: SinglyLinkedListChain<E>) {
    unowned(unsafe) var node = chain.head
    unowned(unsafe) let last = chain.tail

    while node !== last {
        unowned(unsafe) let next = node.next!
        node.release()
        node = next
    }
    node.release()
}

// MARK: - UnsafeSinglyLinkedList

final class UnsafeSinglyLinkedList<Element> {
    unowned(unsafe) var head: SinglyLinkedListNode<Element>
    unowned(unsafe) var tail: SinglyLinkedListNode<Element>

    init() {
        head = SinglyLinkedListNode.makeRetained()
        tail = head
    }

    deinit {
        if let first = head.next {
            releaseChain(SinglyLinkedListChain(head: first, tail: tail))
        }
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
            unowned(unsafe) let clone = makeClone(mark: &first)
            last = first

            return clone
        }

        let leadingChain = cloneChain(SinglyLinkedListChain(head: head, tail: first), mark: &first)
        let trailingChain = cloneChain(SinglyLinkedListChain(head: last, tail: tail), mark: &last)

        // Attach leading and trailing chains.
        leadingChain.tail.unext = trailingChain.head.unmanaged()

        return UnsafeSinglyLinkedList(head: leadingChain.head, tail: trailingChain.tail)
    }

    func attach(node: SinglyLinkedListNode<Element>) {
        tail.unext = node.unmanaged()
        tail = node
    }

    func attach(node: SinglyLinkedListNode<Element>, after last: SinglyLinkedListNode<Element>) {
        let next = last.next    // In case `first` and `last` point to the same node.
        last.unext = node.unmanaged()
        node.unext = next?.unmanaged()

        if last === tail {
            tail = node
        }
    }

    func attach(chain: SinglyLinkedListChain<Element>) {
        tail.unext = chain.head.unmanaged()
        tail = chain.tail
    }

    func attach(chain: SinglyLinkedListChain<Element>, after last: SinglyLinkedListNode<Element>) {
        attach(chain: chain, after: last, skipping: last)
    }

    func attach(chain: SinglyLinkedListChain<Element>,
                after first: SinglyLinkedListNode<Element>,
                skipping last: SinglyLinkedListNode<Element>) {
        let next = last.next
        if first !== last {
            releaseChain(SinglyLinkedListChain(head: first.next!, tail: last))
        }

        first.unext = chain.head.unmanaged()
        chain.tail.unext = next?.unmanaged()

        if last === tail {
            tail = chain.tail
        }
    }

    func abandon(after node: SinglyLinkedListNode<Element>) -> Element {
        let next = node.next!
        abandon(after: node, including: next)

        return next.element
    }

    func abandon(after first: SinglyLinkedListNode<Element>, including last: SinglyLinkedListNode<Element>) {
        let next = last.next
        if first !== last {
            releaseChain(SinglyLinkedListChain(head: first.next!, tail: last))
        }

        first.unext = next?.unmanaged()

        if last === tail {
            tail = first
        }
    }
}
