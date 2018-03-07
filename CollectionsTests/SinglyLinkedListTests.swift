//
//  CollectionsTests.swift
//  CollectionsTests
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import XCTest
@testable import Collections

class CollectionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEmptyList() {
        let list = SinglyLinkedList<Int>()

        XCTAssertTrue(list.isEmpty, "The list is not empty")
        XCTAssertEqual(list.count, 0, "The list count is not equal to zero")
        XCTAssertEqual(list.distance(from: list.startIndex, to: list.endIndex), 0, "Total distance is not equal to zero")
        XCTAssertNil(list.first, "The first element is not nil")
    }

    func testAppendNode() {
        let nodes = [
            SinglyLinkedListNode(1),
            SinglyLinkedListNode(2),
            SinglyLinkedListNode(3),
            SinglyLinkedListNode(4),
            SinglyLinkedListNode(5),
        ]

        var list = SinglyLinkedList<Int>()
        for n in nodes {
            list.append(node: n)
        }

        XCTAssertTrue(nodes[0].next === nodes[1], "The `next` property of first node does not point to second one")
        XCTAssertTrue(nodes[1].next === nodes[2], "The `next` property of second node does not point to third one")
        XCTAssertTrue(nodes[2].next === nodes[3], "The `next` property of third node does not point to fourth one")
        XCTAssertTrue(nodes[3].next === nodes[4], "The `next` property of fourth node does not point to fifth one")
        XCTAssertNil(nodes[4].next, "The `next` property of fifth node is not nil")

        XCTAssertTrue(!list.isEmpty, "The list is empty")
        XCTAssertEqual(list.count, 5, "The list count is not equal to five")
        XCTAssertEqual(list.distance(from: list.startIndex, to: list.endIndex), 5, "Total distance is not equal to five")
        XCTAssertEqual(list.first, 1, "The first element is not `1`")
    }

    func testInsertNode() {
        let nodes = [
            SinglyLinkedListNode(1),
            SinglyLinkedListNode(2),
            SinglyLinkedListNode(3),
            SinglyLinkedListNode(4),
            SinglyLinkedListNode(5),
        ]

        var list = SinglyLinkedList<Int>()
        for n in nodes {
            list.insert(node: n, at: list.startIndex)
        }

        XCTAssertNil(nodes[0].next, "The `next` property of first node is not nil")
        XCTAssertTrue(nodes[1].next === nodes[0], "The `next` property of second node does not point to first one")
        XCTAssertTrue(nodes[2].next === nodes[1], "The `next` property of third node does not point to second one")
        XCTAssertTrue(nodes[3].next === nodes[2], "The `next` property of fourth node does not point to third one")
        XCTAssertTrue(nodes[4].next === nodes[3], "The `next` property of fifth node does not point to fourth one")

        XCTAssertTrue(!list.isEmpty, "The list is empty")
        XCTAssertEqual(list.count, 5, "The list count is not equal to five")
        XCTAssertEqual(list.distance(from: list.startIndex, to: list.endIndex), 5, "Total distance is not equal to five")
        XCTAssertEqual(list.first, 5, "The first element is not `5`")
    }
}
