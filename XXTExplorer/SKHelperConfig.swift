//
//  SKHelperConfig.swift
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

import Foundation
import UIKit

@objc(SKHelperConfig)
open class SKHelperConfig : NSObject {
    public var bundle: Bundle = Bundle.main
    public var font: UIFont = UIFont.systemFont(ofSize: 14)
    public var color: UIColor = UIColor.black
    public var path: String = ""
    public var themeIdentifier: String = ""
    public var languageIdentifier: String = ""
}
