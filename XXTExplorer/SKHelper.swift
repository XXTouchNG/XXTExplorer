//
//  SKHelper.swift
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

import Foundation
import UIKit

//@objc
//protocol SKHelperDelegate: NSObjectProtocol {
//    func helperDidFinishInitialLoad(sender: SKHelper, result: NSAttributedString)
//    func helperDidFailInitialLoad(sender: SKHelper, error: NSError)
//}

@objc(SKHelper)
open class SKHelper : NSObject {
    fileprivate var language: Language? = nil
    fileprivate var theme: Theme? = nil
    init(config: SKHelperConfig) {
        super.init()
        let manager = self.getBundleManager(config: config)
        self.language = manager.language(withIdentifier: config.languageIdentifier)!
        let font = config.font
        self.theme = manager.theme(withIdentifier: config.themeIdentifier, font: font)!
    }
    internal func getBundleManager(config: SKHelperConfig) -> BundleManager {
        return BundleManager { identifier, kind in
            let components = identifier._split(separator: ".")
            if kind == .language && components.count > 1 {
                let name = components[1]
                let ext = ".tmLanguage"
                return config.bundle.url(forResource: name, withExtension: ext) ?? URL(fileURLWithPath: "")
            }
            else if kind == .theme {
                let name = identifier
                let ext = ".tmTheme"
                return config.bundle.url(forResource: name, withExtension: ext) ?? URL(fileURLWithPath: "")
            }
            return URL(fileURLWithPath: "")
        }
    }
    
    @objc
    public func attributedParser() -> AttributedParser? {
        let parser = AttributedParser(language: language!, theme: theme!)
        return parser
    }
    
    @objc
    public func newAttributedOperation(string: String, callback: @escaping AttributedParsingOperation.OperationCallback) -> AttributedParsingOperation? {
        let operation = AttributedParsingOperation(string: string, language: self.language!, theme: self.theme!, callback: callback);
        return operation
    }
    
    @objc func attributedOperation(string: String, previousOperation: AttributedParsingOperation, changeIsInsertion: Bool, changedRange: NSRange) -> AttributedParsingOperation? {
        let operation = AttributedParsingOperation(string: string, previousOperation: previousOperation, changeIsInsertion: changeIsInsertion, changedRange: changedRange)
        return operation
    }
}
