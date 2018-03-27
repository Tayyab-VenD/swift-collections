//
//  CollectionsTests.swift
//  CollectionsTests
//
//  Created by Muhammad Tayyab Akram on 05/03/2018.
//  Copyright © 2018 Muhammad Tayyab Akram. All rights reserved.
//

import XCTest
@testable import Collections

class DoublyLinkedListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmptyList() {
        let list = LinkedList<Int>()

        XCTAssertEqual(list.count, 0, "The list count is not equal to zero")
        XCTAssertEqual(list.distance(from: list.startIndex, to: list.endIndex), 0, "Total distance is not equal to zero")
        XCTAssertTrue(list.isEmpty, "The list is not empty")
        XCTAssertNil(list.first, "The first element is not nil")
        XCTAssertNil(list.last, "The last element is not nil")
    }

    func testElementSubscript() {
        var list = LinkedList([-3, -2, -1])

        var index = list.startIndex
        list[index] = 1
        list.formIndex(after: &index)
        list[index] = 2
        list.formIndex(after: &index)
        list[index] = 3

        var values: [Int] = []
        index = list.startIndex
        values.append(list[index])
        list.formIndex(after: &index)
        values.append(list[index])
        list.formIndex(after: &index)
        values.append(list[index])

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not written correctly")
    }

    func testSliceSubscript() {
        let list = LinkedList([-3, -2, -1, 0, 0, 0, 1, 2, 3])
        let slice1 = list[list.startIndex..<list.index(list.startIndex, offsetBy: 3)]
        let slice2 = list[slice1.endIndex..<list.index(slice1.endIndex, offsetBy: 3)]
        let slice3 = list[slice2.endIndex..<list.endIndex]

        XCTAssertEqual(Array(slice1), [-3, -2, -1], "The elements of first slice are not correct")
        XCTAssertEqual(Array(slice2), [0, 0, 0], "The elements of second slice are not correct")
        XCTAssertEqual(Array(slice3), [1, 2, 3], "The elements of third slice are not correct")
    }

    func testSwapAt() {
        var list = LinkedList([3, 2, 1])
        list.swapAt(list.startIndex, list.index(list.startIndex, offsetBy: 2))

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not swapped")
    }

    func testNodes() {
        let list = LinkedList([1, 2, 3])
        let nodes = Array(list.nodes)
        let values = [
            nodes[0].element,
            nodes[1].element,
            nodes[2].element
        ]

        XCTAssertTrue(nodes[0].next === nodes[1], "The `next` property of first node does not point to second one")
        XCTAssertTrue(nodes[1].next === nodes[2], "The `next` property of second node does not point to third one")
        XCTAssertEqual(values, [1, 2, 3], "The values of nodes are not expected ones")
    }

    func testAppendElement() {
        var list = LinkedList<Int>()
        list.append(1)
        list.append(2)
        list.append(3)

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not appended correctly")
    }

    func testInsertElement() {
        var list = LinkedList<Int>()
        list.insert(3, at: list.endIndex)
        list.insert(1, at: list.startIndex)
        list.insert(2, at: list.index(list.startIndex, offsetBy: 1))

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not inserted correctly")
    }

    func testAppendSequence() {
        var list = LinkedList<Int>()
        list.append(contentsOf: [1, 2])
        list.append(contentsOf: [    ])
        list.append(contentsOf: [3   ])

        XCTAssertEqual(Array(list), [1, 2, 3], "The sequences are not appended correctly")
    }

    func testInsertSequence() {
        var list = LinkedList<Int>()
        list.insert(contentsOf: [3], at: list.endIndex)
        list.insert(contentsOf: [ ], at: list.startIndex)
        list.insert(contentsOf: [1], at: list.startIndex)
        list.insert(contentsOf: [2], at: list.index(list.startIndex, offsetBy: 1))

        XCTAssertEqual(Array(list), [1, 2, 3], "The collections are not inserted correctly")
    }

    func testRemoveFirst() {
        var list = LinkedList([-3, -2, -1, 1, 2, 3])
        let removed = [
            list.removeFirst(),
            list.removeFirst(),
            list.removeFirst()
        ]

        XCTAssertEqual(removed, [-3, -2, -1], "The removed elements are not expected ones")
        XCTAssertEqual(Array(list), [1, 2, 3], "The remaining elements are not expected ones")
    }

    func testRemoveAt() {
        var list = LinkedList([-3, 1, 2, -2, 3, -1])
        let removed = [
            list.remove(at: list.startIndex),
            list.remove(at: list.index(list.startIndex, offsetBy: 2)),
            list.remove(at: list.index(list.startIndex, offsetBy: 3)),
        ]

        XCTAssertEqual(removed, [-3, -2, -1], "The removed elements are not expected ones")
        XCTAssertEqual(Array(list), [1, 2, 3], "The remaining elements are not expected ones")
    }

    func testRemoveSubrange() {
        var list = LinkedList([-4, 1, 2, -3, -2, 3, -1])
        list.removeSubrange(list.startIndex..<list.index(after: list.startIndex))
        list.removeSubrange(list.index(list.startIndex, offsetBy: 2)..<list.index(list.startIndex, offsetBy: 4))
        list.removeSubrange(list.index(list.startIndex, offsetBy: 3)..<list.endIndex)

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not removed correctly")
    }

    func testRemoveAll() {
        var list = LinkedList([-1, -2, -3])
        list.removeAll()

        XCTAssertEqual(Array(list), [], "The list is not empty")
    }

    func testReplaceSubrangeSlices() {
        var list = LinkedList([-4, 2, -3, -2, 3, -1])
        list.replaceSubrange(list.startIndex..<list.index(list.startIndex, offsetBy: 3), with:[1])
        list.replaceSubrange(list.index(list.startIndex, offsetBy: 1)..<list.index(list.startIndex, offsetBy: 4), with:[])
        list.replaceSubrange(list.endIndex..<list.endIndex, with: [2, 3])

        XCTAssertEqual(Array(list), [1, 2, 3], "The elements are not replaced correctly")
    }

    func testReplaceSubrangeEmpty() {
        var list = LinkedList([1, 2, 3])
        list.replaceSubrange(list.startIndex..<list.endIndex, with: [])

        XCTAssertEqual(Array(list), [], "The list is not empty")
    }

    func testCopyOnWriteEmpty() {
        let list = LinkedList<Int>()

        var copy = list
        copy.append(contentsOf: [1, 2, 3])

        XCTAssertEqual(Array(list), [], "The constant list is not at original state")
        XCTAssertEqual(Array(copy), [1, 2, 3], "Copy on write didn't work correctly")
    }

    func testCopyOnWriteComplete() {
        let list = LinkedList([1, 2, 3])

        var copy = list
        copy.removeSubrange(copy.startIndex..<copy.endIndex)

        XCTAssertEqual(Array(list), [1, 2, 3], "The constant list is not at original state")
        XCTAssertEqual(Array(copy), [], "Copy on write didn't work correctly")
    }

    func testCopyOnWriteIndex() {
        let list = LinkedList([1, 2, 3])
        let index = list.index(after: list.startIndex)

        var copy = list
        copy[index] = -2

        XCTAssertEqual(Array(list), [1, 2, 3], "The constant list is not at original state")
        XCTAssertEqual(Array(copy), [1, -2, 3], "Copy on write didn't work correctly")
    }

    func testCopyOnWriteSwap() {
        let list = LinkedList([1, 2, 3])

        var copy = list
        copy.swapAt(list.startIndex, list.index(before:list.endIndex))

        XCTAssertEqual(Array(list), [1, 2, 3], "The constant list is not at original state")
        XCTAssertEqual(Array(copy), [3, 2, 1], "Copy on write didn't work correctly")
    }

    func testCopyOnWriteRange() {
        let list = LinkedList([-3, -2, -1, 1, 2, 3])
        let range = list.index(after: list.startIndex)..<list.index(list.endIndex, offsetBy: -1)

        var copy = list
        copy.replaceSubrange(range, with: [0])

        XCTAssertEqual(Array(list), [-3, -2, -1, 1, 2, 3], "The constant list is not at original state")
        XCTAssertEqual(Array(copy), [-3, 0, 3], "Copy on write didn't work correctly")
    }
}
