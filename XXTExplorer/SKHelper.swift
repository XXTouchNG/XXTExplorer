//
//  SKHelper.swift
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

import Foundation
import UIKit

@objc
protocol SKHelperDelegate: NSObjectProtocol {
    func helperDidFinishInitialLoad(sender: SKHelper, result: NSAttributedString)
    func helperDidFailInitialLoad(sender: SKHelper, error: NSError)
}

@objc(SKHelper)
open class SKHelper : NSObject {
    weak var delegate: SKHelperDelegate?
    public var config: SKHelperConfig
    init(config: SKHelperConfig) {
        self.config = config
    }
    fileprivate func fixture(name: String, type: String) -> String? {
        let path = config.bundle.path(forResource: name, ofType: type)
        do {
            if let path = path {
                return try String(contentsOfFile: path)
            }
        } catch {
            return nil
        }
        return nil
    }
    internal func getBundleManager() -> BundleManager {
        return BundleManager { identifier, kind in
            let components = identifier._split(separator: ".")
            if kind == .language && components.count > 1 {
                let name = components[1]
                let ext = ".tmLanguage"
                return self.config.bundle.url(forResource: name, withExtension: ext) ?? URL(fileURLWithPath: "")
            }
            else if kind == .theme {
                let name = identifier
                let ext = ".tmTheme"
                return self.config.bundle.url(forResource: name, withExtension: ext) ?? URL(fileURLWithPath: "")
            }
            return URL(fileURLWithPath: "")
        }
    }
    public func initialLoad() -> NSAttributedString? {
        do {
            let manager = self.getBundleManager()
            let input = try String(contentsOfFile: config.path)
            let language = manager.language(withIdentifier: config.languageIdentifier)
            let font = config.font
            let theme = manager.theme(withIdentifier: config.themeIdentifier, font: font)
            if let language = language, let theme = theme {
                let parser = AttributedParser(language: language, theme: theme)
                let resultString = parser.attributedString(for: input, base: [NSFontAttributeName: config.font, NSForegroundColorAttributeName: config.color])
                delegate?.helperDidFinishInitialLoad(sender: self, result: resultString)
                return resultString
            }
        } catch let error {
            delegate?.helperDidFailInitialLoad(sender: self, error: error as NSError)
        }
        return nil
    }
}
