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

    func node(at index: Index) -> Node
}

public protocol LinkedMutableCollection : LinkedCollection, MutableCollection {
}

public protocol LinkedRangeReplaceableCollection : LinkedMutableCollection, RangeReplaceableCollection {
    mutating func append(node: Node)
    mutating func insert(node: Node, at i: Index)
}
