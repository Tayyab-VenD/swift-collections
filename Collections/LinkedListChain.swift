//
//  LinkedListChain.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 16/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

typealias LinkedListChain<Element> = (head: LinkedListNode<Element>, tail: LinkedListNode<Element>)

public final class LinkedListNode<Element> {
    var element: Element!
    internal(set) public var next: LinkedListNode<Element>? = nil
    internal(set) public weak var previous: LinkedListNode<Element>? = nil

    internal init() {
    }

    init(_ element: Element!) {
        self.element = element
    }

    public var value: Element {
        return element!
    }
}

func makeChain<S>(_ elements: S) -> LinkedListChain<S.Element>? where S : Sequence {
    // Proceed if collection contains at least one element.
    var iterator = elements.makeIterator()
    if let element = iterator.next() {
        // Create node for first element.
        var chain: LinkedListChain<S.Element>
        chain.head = LinkedListNode(element)
        chain.tail = chain.head

        // Create nodes for remaining elements.
        while let element = iterator.next() {
            let current = LinkedListNode(element)
            current.previous = chain.tail
            chain.tail.next = current
            chain.tail = current
        }

        return chain
    }

    return nil
}

func cloneChain<E>(_ chain: LinkedListChain<E>, mark: inout LinkedListNode<E>) -> LinkedListChain<E> {
    // Clone first node.
    let head = LinkedListNode(chain.head.element)
    var tail = head

    if mark === chain.head {
        mark = head
    }

    var node = chain.head.next
    let limit = chain.tail.next

    // Clone remaining nodes.
    while node !== limit {
        let clone = LinkedListNode(node!.element)
        clone.previous = tail
        tail.next = clone
        tail = clone

        if node === mark {
            mark = clone
        }

        node = node!.next
    }

    return LinkedListChain(head: head, tail: tail)
}

func attach<E>(node: LinkedListNode<E>, after target: LinkedListNode<E>) {
    attach(node: node, after: target, before: target.next!)
}

func attach<E>(node: LinkedListNode<E>, after first: LinkedListNode<E>, before last: LinkedListNode<E>) {
    last.previous = node
    node.next = last
    node.previous = first
    first.next = node
}

func attach<E>(chain: LinkedListChain<E>, after target: LinkedListNode<E>) {
    attach(chain: chain, after: target, before: target.next!)
}

func attach<E>(chain: LinkedListChain<E>, after first: LinkedListNode<E>, before last:LinkedListNode<E>) {
    last.previous = chain.tail
    chain.tail.next = last
    chain.head.previous = first
    first.next = chain.head
}

func abandon<E>(node: LinkedListNode<E>) -> E {
    abandon(after: node.previous!, before: node.next!)
    return node.element
}

func abandon<E>(after first: LinkedListNode<E>, before last: LinkedListNode<E>) {
    last.previous = first
    first.next = last
}
