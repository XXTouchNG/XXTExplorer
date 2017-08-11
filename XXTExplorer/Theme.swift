//
//  Theme.swift
//  SyntaxKit
//
//  Represents a TextMate theme file (.tmTheme). Currently only supports the
//  foreground text color attribute on a local scope.
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

public typealias Attributes = [String: AnyObject]

public enum FontStyle: String {
    case regular = "regular"
    case underline = "underline"
    case bold = "bold"
    case italic = "italic"
    case boldItalic = "boldItalic"
    case strikeThrough = "strikeThrough"
}

public struct Theme {

    // MARK: - Properties

    public let uuid: UUID
    public let name: String
    public let attributes: [String: Attributes]

    public var backgroundColor: Color {
        return attributes[Language.globalScope]?[NSBackgroundColorAttributeName] as? Color ?? Color.white
    }

    public var foregroundColor: Color {
        return attributes[Language.globalScope]?[NSForegroundColorAttributeName] as? Color ?? Color.black
    }

    // MARK: - Initializers

    init?(dictionary: [String: Any], font: UIFont? = UIFont.systemFont(ofSize: 14)) {
        
        guard let uuidString = dictionary["uuid"] as? String,
            let uuid = UUID(uuidString: uuidString),
            let name = dictionary["name"] as? String,
            let rawSettings = dictionary["settings"] as? [[String: AnyObject]]
            else { return nil }
        
        guard let font = font else { return nil }
        let boldFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: 0)
        let italicFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: 0)
        let boldItalicFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])!, size: 0)

        self.uuid = uuid
        self.name = name

        var attributes = [String: Attributes]()
        for raw in rawSettings {
            guard var setting = raw["settings"] as? [String: AnyObject] else { continue }

            if let value = setting.removeValue(forKey: "foreground") as? String {
                setting[NSForegroundColorAttributeName] = Color(hex: value)
            }

            if let value = setting.removeValue(forKey: "background") as? String {
                setting[NSBackgroundColorAttributeName] = Color(hex: value)
            }
            
            if let value = setting.removeValue(forKey: "fontStyle") as? String {
                switch value {
                case FontStyle.regular.rawValue:
                    setting[NSFontAttributeName] = font
                case FontStyle.bold.rawValue:
                    setting[NSFontAttributeName] = boldFont
                case FontStyle.italic.rawValue:
                    setting[NSFontAttributeName] = italicFont
                case FontStyle.boldItalic.rawValue:
                    setting[NSFontAttributeName] = boldItalicFont
                case FontStyle.underline.rawValue:
                    setting[NSUnderlineStyleAttributeName] = NSUnderlineStyle.styleSingle as AnyObject
                case FontStyle.strikeThrough.rawValue:
                    setting[NSBaselineOffsetAttributeName] = 0 as AnyObject
                    setting[NSStrikethroughStyleAttributeName] = NSUnderlineStyle.styleSingle as AnyObject
                default: break
                }
            }

            if let patternIdentifiers = raw["scope"] as? String {
                for patternIdentifier in patternIdentifiers.components(separatedBy: ",") {
                    let key = patternIdentifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    attributes[key] = setting
                }
            } else if !setting.isEmpty {
                attributes[Language.globalScope] = setting
            }
        }
        self.attributes = attributes
    }
}
