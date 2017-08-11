//
//  Result.swift
//  SyntaxKit
//
//  Represents a match by the parser.
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

internal struct Result: Equatable {

    // MARK: - Properties

    let patternIdentifier: String
    var range: NSRange
    let attribute: AnyObject?

    // MARK: - Initializers

    init(identifier: String, range: NSRange, attribute: AnyObject? = nil) {
        self.patternIdentifier = identifier
        self.range = range
        self.attribute = attribute
    }
}

internal func == (lhs: Result, rhs: Result) -> Bool {
    return lhs.patternIdentifier == rhs.patternIdentifier &&
        lhs.range.toRange() == rhs.range.toRange()
}
