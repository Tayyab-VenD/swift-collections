//
//  UnsafeList.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 22/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

public final class LinkedListNode<Element> {
    var optionalElement: Element!
    var unsafeNext: UnsafeNode<Element>? = nil
    var unsafePrevious: UnsafeNode<Element>? = nil

    internal init() {
    }

    init(_ element: Element!) {
        self.optionalElement = element
    }

    public var element: Element {
        return optionalElement!
    }

    public var next: LinkedListNode<Element>? {
        return unsafeNext?.instance
    }

    public var previous: LinkedListNode<Element>? {
        return unsafePrevious?.instance
    }
}

struct UnsafeNode<Element> {
    unowned(unsafe) let instance: LinkedListNode<Element>

    @inline(__always)
    static func make(_ element: Element! = nil) -> UnsafeNode<Element> {
        let instance = LinkedListNode<Element>(element)
        return UnsafeNode(instance).retain()
    }

    @inline(__always)
    private init(_ instance: LinkedListNode<Element>) {
        self.instance = instance
    }

    var next: UnsafeNode<Element> {
        @inline(__always)
        get {
            return instance.unsafeNext!
        }
        @inline(__always)
        nonmutating set(value) {
            instance.unsafeNext = value
        }
    }

    var previous: UnsafeNode<Element> {
        @inline(__always)
        get {
            return instance.unsafePrevious!
        }
        @inline(__always)
        nonmutating set(value) {
            instance.unsafePrevious = value
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
    func retain() -> UnsafeNode<Element> {
        let _ = Unmanaged.passRetained(instance)
        return self
    }

    @inline(__always)
    func release() {
        instance.unsafeNext = nil
        instance.unsafePrevious = nil
        Unmanaged.passUnretained(instance).release()
    }
}

extension UnsafeNode : Equatable {
    @inline(__always)
    static func ==(lhs: UnsafeNode<Element>, rhs: UnsafeNode<Element>) -> Bool {
        return lhs.instance === rhs.instance
    }
}

struct UnsafeChain<Element> {
    var head: UnsafeNode<Element>
    var tail: UnsafeNode<Element>

    static func make<S>(_ elements: S) -> UnsafeChain<S.Element>? where S : Sequence, Element == S.Element {
        // Proceed if collection contains at least one element.
        var iterator = elements.makeIterator()
        if let element = iterator.next() {
            // Make node for first element and initialize the chain.
            let first = UnsafeNode.make(element)
            var chain =  UnsafeChain(head: first, tail: first)

            // Make nodes for remaining elements.
            while let element = iterator.next() {
                let current = UnsafeNode.make(element)
                current.previous = chain.tail
                chain.tail.next = current
                chain.tail = current
            }

            return chain
        }

        return nil
    }


    func clone(marking nodes: inout [UnsafeNode<Element>]) -> UnsafeChain<Element> {
        // Clone first node and initialize the chain.
        let first = UnsafeNode.make(head.element)
        var clone = UnsafeChain(head: first, tail: first)
        if let index = nodes.index(of: head) {
            nodes[index] = first
        }

        var node = head.next
        let limit = tail.next

        // Clone remaining nodes.
        while node != limit {
            let copy = UnsafeNode.make(node.element)
            copy.previous = clone.tail
            clone.tail.next = copy
            clone.tail = copy
            if let index = nodes.index(of: node) {
                nodes[index] = copy
            }

            node = node.next
        }

        return clone
    }

    func release() {
        var node = head
        let last = tail

        while node != last {
            let next = node.next
            node.release()
            node = next
        }
        node.release()
    }
}

final class UnsafeList<Element> {
    var head: UnsafeNode<Element>

    init() {
        head = UnsafeNode.make()
        head.next = head
        head.previous = head
    }

    private init(head: UnsafeNode<Element>) {
        self.head = head
    }

    deinit {
        UnsafeChain(head: head.previous, tail: head.next).release()
    }

    func clone(marking nodes: inout [UnsafeNode<Element>]) -> UnsafeList<Element> {
        let chain = UnsafeChain(head: head, tail: head.previous)
        let clone = chain.clone(marking: &nodes)
        clone.tail.next = clone.head
        clone.head.previous = clone.tail

        return UnsafeList(head: clone.head)
    }

    func clone(skippingAfter first: inout UnsafeNode<Element>,
               skippingBefore last: inout UnsafeNode<Element>) -> UnsafeList<Element> {
        var fmark = [first]
        var lmark = [last]
        
        guard first != last else {
            defer {
                first = fmark[0]
                last = first
            }
            return clone(marking: &fmark)
        }

        let leadingChain = UnsafeChain(head: head.next, tail: first).clone(marking: &fmark)
        let trailingChain = UnsafeChain(head: last, tail: head).clone(marking: &lmark)

        // Set the mark nodes.
        first = fmark[0]
        last = lmark[0]
        
        // Attach leading and trailing chains.
        trailingChain.head.previous = leadingChain.tail
        leadingChain.tail.next = trailingChain.head

        // Make the chain circular.
        trailingChain.tail.next = leadingChain.head
        leadingChain.head.previous = trailingChain.tail

        return UnsafeList(head: trailingChain.tail)
    }

    func attach(node: UnsafeNode<Element>, after last: UnsafeNode<Element>) {
        let next = last.next
        next.previous = node
        node.next = next
        node.previous = last
        last.next = node
    }

    func attach(chain: UnsafeChain<Element>, after last: UnsafeNode<Element>) {
        attach(chain: chain, after: last, before: last.next)
    }

    func attach(chain: UnsafeChain<Element>, after first: UnsafeNode<Element>, before last:UnsafeNode<Element>) {
        let next = first.next
        if next != last {
            UnsafeChain(head: next, tail: last.previous).release()
        }
        
        last.previous = chain.tail
        chain.tail.next = last
        chain.head.previous = first
        first.next = chain.head
    }

    func abandon(node: UnsafeNode<Element>) -> Element {
        let element = node.element!
        abandon(after: node.previous, before: node.next)
        
        return element
    }

    func abandon(after first: UnsafeNode<Element>, before last: UnsafeNode<Element>) {
        let next = first.next
        if next != last {
            UnsafeChain(head: next, tail: last.previous).release()
        }

        last.previous = first
        first.next = last
    }
}
