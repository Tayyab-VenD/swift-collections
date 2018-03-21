//
//  LinkedCollection.swift
//  Collections
//
//  Created by Muhammad Tayyab Akram on 07/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import Foundation

public protocol LinkedCollection : Collection {
    associatedtype Node
    associatedtype Nodes : Collection = DefaultNodes<Self>
        where Nodes.Element == Node,
              Nodes.SubSequence == Nodes

    func node(at index: Index) -> Node
    var nodes: Nodes { get }
}

extension LinkedCollection {
    public var nodes: DefaultNodes<Self> {
        return DefaultNodes(elements: self, startIndex: startIndex, endIndex: endIndex)
    }
}

public struct DefaultNodes<Elements: LinkedCollection> {
    private var elements: Elements
    public private(set) var startIndex: Index
    public private(set) var endIndex: Index

    init(elements: Elements, startIndex: Index, endIndex: Index) {
        self.elements = elements
        self.startIndex = startIndex
        self.endIndex = endIndex
    }
}

extension DefaultNodes : Collection {
    public typealias Index = Elements.Index
    public typealias Element = Elements.Node
    public typealias Indices = Elements.Indices
    public typealias SubSequence = DefaultNodes<Elements>

    public subscript(i: Index) -> Element {
        return elements.node(at: i)
    }

    public subscript(bounds: Range<Index>) -> DefaultNodes<Elements> {
        return DefaultNodes(elements: elements,
                            startIndex: bounds.lowerBound,
                            endIndex: bounds.upperBound)
    }

    public func index(after i: Index) -> Index {
        return elements.index(after: i)
    }

    public func formIndex(after i: inout Index) {
        elements.formIndex(after: &i)
    }

    public var indices: Indices {
        return elements.indices
    }
}
