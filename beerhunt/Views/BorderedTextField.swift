//
//  BorderedTextView.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/16.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

@IBDesignable
class BorderedTextField: UITextField {

    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var borderWidth: CGFloat = 0.0
    @IBInspectable var borderColor: CGColor = UIColor.white.cgColor

    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }

}
