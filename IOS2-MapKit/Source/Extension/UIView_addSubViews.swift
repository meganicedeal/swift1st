//
//  UIView_addSubViews.swift
//  MapKit
//
//  Created by Daniel Carvalho on 22/02/22.
//

import Foundation
import UIKit

extension UIView {
    
    func addSubviews( _ subviews : UIView... ){
        // _ in front of a parameter will dismiss the
        // use of the label
        
        for subview in subviews {
            self.addSubview(subview)
        }
        
    }
    
}
