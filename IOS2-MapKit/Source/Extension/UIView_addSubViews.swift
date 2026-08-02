//
//  UIView_addSubViews.swift
//  MapKit
//
//  Created by Daniel Carvalho on 22/02/22.
//

import Foundation
import UIKit

// THEORY: this is a different use of `extension` than the ones in
// UICoordinatePanel.swift. There, we extended a protocol WE wrote. Here,
// we're extending `UIView` — a type from Apple's own UIKit framework that
// we don't own and can't edit the source of. Swift lets you add new
// methods to ANY existing type this way, which is how the whole codebase
// gets to call `someView.addSubviews(a, b, c)` and
// `someView.enableTapGestureRecognizer(...)` even though Apple never wrote
// those methods — we bolted them on ourselves, once, here.
extension UIView {
    
    // `_ subviews : UIView...` is a VARIADIC parameter: the `...` means the
    // caller can pass zero, one, or many UIViews as plain comma-separated
    // arguments (`addSubviews(a, b, c)`) and Swift collects them into a
    // `[UIView]` array named `subviews` inside the function body.
    func addSubviews( _ subviews : UIView... ){
        // _ in front of a parameter will dismiss the
        // use of the label
        
        for subview in subviews {
            self.addSubview(subview)
        }
        
    }
    
}
