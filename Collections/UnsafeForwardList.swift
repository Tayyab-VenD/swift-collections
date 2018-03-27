//
//  UnsafeForwardList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 22/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

public final class SinglyLinkedListNode<Element> {
    var optionalElement: Element!
    var unsafeNext: UnsafeForwardNode<Element>?

    init(_ element: Element!) {
        self.optionalElement = element
    }

    public var element: Element {
        return optionalElement!
    }

    public var next: SinglyLinkedListNode<Element>? {
        return unsafeNext?.instance
    }
}

struct UnsafeForwardNode<Element> : Equatable {
    unowned(unsafe) let instance: SinglyLinkedListNode<Element>

    @inline(__always)
    static func ==(lhs: UnsafeForwardNode<Element>, rhs: UnsafeForwardNode<Element>) -> Bool {
        return lhs.instance === rhs.instance
    }

    @inline(__always)
    static func make(_ element: Element! = nil) -> UnsafeForwardNode<Element> {
        let instance = SinglyLinkedListNode<Element>(element)
        return UnsafeForwardNode(instance).retain()
    }

    @inline(__always)
    private init(_ instance: SinglyLinkedListNode<Element>) {
        self.instance = instance
    }

    var next: UnsafeForwardNode<Element>? {
        @inline(__always)
        get {
            return instance.unsafeNext
        }
        @inline(__always)
        nonmutating set(value) {
            instance.unsafeNext = value
        }
    }

    var element: Element! {
        @inline(__always)
        get {
            return instance.optionalElement
        }
        @inline(__always)
        nonmutating set(value) {
            instance.optionalElement = value
        }
    }

    @inline(__always)
    func retain() -> UnsafeForwardNode<Element> {
        let _ = Unmanaged.passRetained(instance)
        return self
    }

    @inline(__always)
    func release() {
        instance.unsafeNext = nil
        Unmanaged.passUnretained(instance).release()
    }
}

struct UnsafeForwardChain<Element> {
    var head: UnsafeForwardNode<Element>
    var tail: UnsafeForwardNode<Element>

    static func make<S>(_ elements: S) -> UnsafeForwardChain<S.Element>? where S : Sequence, Element == S.Element {
        // Proceed if collection contains at least one element.
        var iterator = elements.makeIterator()
        if let element = iterator.next() {
            // Make node for first element and initialize the chain.
            let first = UnsafeForwardNode.make(element)
            var chain = UnsafeForwardChain(head: first, tail: first)

            // Make nodes for remaining elements.
            while let element = iterator.next() {
                let node = UnsafeForwardNode.make(element)
                chain.tail.next = node
                chain.tail = node
            }

            return chain
        }

        return nil
    }

    func clone(marking nodes: inout [UnsafeForwardNode<Element>]) -> UnsafeForwardChain<Element> {
        // Clone first node and initialize the chain.
        let first = UnsafeForwardNode.make(head.element)
        var clone = UnsafeForwardChain(head: first, tail: first)
        if let index = nodes.index(of: head) {
            nodes[index] = first
        }

        var node = head.next
        let limit = tail.next

        // Clone remaining nodes.
        while node != limit {
            let copy = UnsafeForwardNode.make(node!.element)
            clone.tail.next = copy
            clone.tail = copy
            if let index = nodes.index(of: node!) {
                nodes[index] = copy
            }

            node = node!.next
        }

        return clone
    }

    func release() {
        var node = head
        let last = tail

        while node != last {
            let next = node.next!
            node.release()
            node = next
        }
        node.release()
    }
}

final class UnsafeForwardList<Element> {
    var head: UnsafeForwardNode<Element>
    var tail: UnsafeForwardNode<Element>

    init() {
        head = UnsafeForwardNode.make()
        tail = head
    }

    deinit {
        UnsafeForwardChain(head: head, tail: tail).release()
    }

    private init(head: UnsafeForwardNode<Element>, tail: UnsafeForwardNode<Element>) {
        self.head = head
        self.tail = tail
    }

    func clone(marking nodes: inout [UnsafeForwardNode<Element>]) -> UnsafeForwardList<Element> {
        let chain = UnsafeForwardChain(head: head, tail: tail)
        let clone = chain.clone(marking: &nodes)

        return UnsafeForwardList(head: clone.head, tail: clone.tail)
    }

    func clone(skippingAfter first: inout UnsafeForwardNode<Element>,
               skippingBefore last: inout UnsafeForwardNode<Element>) -> UnsafeForwardList<Element> {
        var fmark = [first]
        var lmark = [last]

        guard first != last else {
            defer {
                first = fmark[0]
                last = first
            }
            return clone(marking: &fmark)
        }

        let leadingChain = UnsafeForwardChain(head: head, tail: first).clone(marking: &fmark)
        let trailingChain = UnsafeForwardChain(head: last, tail: tail).clone(marking: &lmark)

        // Set the mark nodes.
        first = fmark[0]
        last = lmark[0]

        // Attach leading and trailing chains.
        leadingChain.tail.next = trailingChain.head

        return UnsafeForwardList(head: leadingChain.head, tail: trailingChain.tail)
    }

    func attach(node: UnsafeForwardNode<Element>) {
        tail.next = node
        tail = node
    }

    func attach(node: UnsafeForwardNode<Element>, after last: UnsafeForwardNode<Element>) {
        let next = last.next    // In case `node` and `last` point to the same node.
        last.next = node
        node.next = next

        if next == nil {
            tail = node
        }
    }

    func attach(chain: UnsafeForwardChain<Element>) {
        tail.next = chain.head
        tail = chain.tail
    }

    func attach(chain: UnsafeForwardChain<Element>, after last: UnsafeForwardNode<Element>) {
        attach(chain: chain, after: last, skipping: last)
    }

    func attach(chain: UnsafeForwardChain<Element>,
                after first: UnsafeForwardNode<Element>,
                skipping last: UnsafeForwardNode<Element>) {
        let next = last.next
        if first != last {
            UnsafeForwardChain(head: first.next!, tail: last).release()
        }

        first.next = chain.head
        chain.tail.next = next

        if next == nil {
            tail = chain.tail
        }
    }

    func abandon(after node: UnsafeForwardNode<Element>) -> Element {
        let next = node.next!
        let element = next.element!
        abandon(after: node, including: next)

        return element
    }

    func abandon(after first: UnsafeForwardNode<Element>, including last: UnsafeForwardNode<Element>) {
        let next = last.next
        if first != last {
            UnsafeForwardChain(head: first.next!, tail: last).release()
        }

        first.next = next

        if next == nil {
            tail = first
        }
    }
}
