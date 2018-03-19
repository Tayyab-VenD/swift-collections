//
//  SinglyLinkedListChain.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 19/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

typealias SinglyLinkedListChain<Element> = (head: SinglyLinkedListNode<Element>, tail: SinglyLinkedListNode<Element>)

public final class SinglyLinkedListNode<Element> {
    var element: Element!
    internal(set) public var next: SinglyLinkedListNode<Element>? = nil

    init() {
    }

    init(_ element: Element!) {
        self.element = element
    }

    public var value: Element {
        return element!
    }
}

func makeChain<S>(_ elements: S) -> SinglyLinkedListChain<S.Element>? where S : Sequence {
    // Proceed if collection contains at least one element.
    var iterator = elements.makeIterator()
    if let element = iterator.next() {
        // Create node for first element.
        var chain: SinglyLinkedListChain<S.Element>
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

func cloneChain<E>(_ chain: SinglyLinkedListChain<E>, mark: inout SinglyLinkedListNode<E>) -> SinglyLinkedListChain<E> {
    // Clone first node.
    let head = SinglyLinkedListNode(chain.head.element)
    var tail = head

    if mark === chain.head {
        mark = head
    }

    var node = chain.head.next
    let limit = chain.tail.next

    // Clone remaining nodes.
    while node !== limit {
        let clone = SinglyLinkedListNode(node!.element)
        tail.next = clone
        tail = clone

        if node === mark {
            mark = clone
        }

        node = node!.next
    }

    return SinglyLinkedListChain(head: head, tail: tail)
}

func attach<E>(node: SinglyLinkedListNode<E>, after tail: inout SinglyLinkedListNode<E>) {
    tail.next = node
    tail = node
}

func attach<E>(node: SinglyLinkedListNode<E>,
               after last: SinglyLinkedListNode<E>,
               revise tail: inout SinglyLinkedListNode<E>) {
    let next = last.next    // In case `first` and `last` point to the same node.
    last.next = node
    node.next = next

    if last === tail {
        tail = node
    }
}

func attach<E>(chain: SinglyLinkedListChain<E>, after tail: inout SinglyLinkedListNode<E>) {
    tail.next = chain.head
    tail = chain.tail
}

func attach<E>(chain: SinglyLinkedListChain<E>,
               after last: SinglyLinkedListNode<E>,
               revise tail: inout SinglyLinkedListNode<E>) {
    attach(chain: chain, after: last, skipping: last, revise: &tail)
}

func attach<E>(chain: SinglyLinkedListChain<E>,
               after first: SinglyLinkedListNode<E>,
               skipping last: SinglyLinkedListNode<E>,
               revise tail: inout SinglyLinkedListNode<E>) {
    let next = last.next    // In case `first` and `last` point to the same node.
    first.next = chain.head
    chain.tail.next = next

    if last === tail {
        tail = chain.tail
    }
}

func abandon<E>(after node: SinglyLinkedListNode<E>, revise tail: inout SinglyLinkedListNode<E>) -> E {
    let next = node.next!
    abandon(after: node, including: next, revise: &tail)

    return next.element
}

func abandon<E>(after first: SinglyLinkedListNode<E>,
                including last: SinglyLinkedListNode<E>,
                revise tail: inout SinglyLinkedListNode<E>) {
    first.next = last.next

    if last === tail {
        tail = first
    }
}
