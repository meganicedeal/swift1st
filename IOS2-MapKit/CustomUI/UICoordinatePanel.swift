//
//  UICoordinatePanel.swift
//  MapKit
//
//  Created by Daniel Carvalho on 17/02/22.
//

import UIKit

// THEORY: this file is the clearest example of the delegate pattern in the
// whole project — read it alongside RouteInfoPanel's delegate below, they
// follow the identical shape on purpose, so once you understand one you
// understand both.
//
// A `protocol` is just a list of method signatures with no implementation —
// a *contract*. It says "any type that conforms to UICoordinatePanelDelegate
// promises to have a coordinatePanelButtonTapped(_:) method", without
// caring at all what that type actually is (a ViewController here, but it
// could be anything).

protocol UICoordinatePanelDelegate {
    // 1: Define the protocol name and methods (function signatures)
    
    // blueprint about methods that should be implemented to communicate
    // between the owner (who created the object) and the object.
    func coordinatePanelButtonTapped( _ sender : Any? )
    
}

// A `protocol extension` can supply a DEFAULT implementation for a method
// declared in the protocol. Here the default does nothing ("no code").
// The practical effect: whoever adopts UICoordinatePanelDelegate is no
// longer *required* to implement coordinatePanelButtonTapped(_:) — if they
// don't, this empty version quietly runs instead. This is how you turn a
// strict protocol into something that behaves like an "optional" delegate
// method (a trick Swift needs because, unlike Objective-C, protocols don't
// have a built-in `@optional` for pure-Swift protocols).
extension UICoordinatePanelDelegate {
    // 4. We are turning this protocol into a delegate, meaning that
    // those functions are now not mandatory to be implemented by
    // the owner (viewController)
    func coordinatePanelButtonTapped( _ sender : Any? ) {
        // no code...
    }
    
}


class UICoordinatePanel: UIView {

    public var delegate : UICoordinatePanelDelegate?
    // 2: Declare the delegate public property to assign the owner (in our case,
    // viewController
    
    static private func defaultLabel( text : String, bold : Bool = false ) -> UILabel {
        
        let lbl = UILabel()
        lbl.text = text
        lbl.font = bold ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16)
        lbl.textColor = .black
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        
        // We will apply constraints programmatically
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        return lbl
        
    }
    
    private var lblLatitudeTitle : UILabel = UICoordinatePanel.defaultLabel(text: "Latitude")
    
    private var lblLongitudeTitle : UILabel = UICoordinatePanel.defaultLabel(text: "Longitude")
    
    private var lblLatitude : UILabel = UICoordinatePanel.defaultLabel(text: "...", bold: true)
    
    private var lblLongitude : UILabel = UICoordinatePanel.defaultLabel(text: "...", bold: true)
    
    
    private var imgPosition : UIImageView = {
        var img = UIImageView()
        img.image = UIImage(systemName: "target")
        img.tintColor = .black
        
        // We will apply constraints programmatically
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    
    // We need setters for Longitude and Latitude...
    // Using didSet
    //
    // THEORY: `didSet` is a PROPERTY OBSERVER. Instead of writing a manual
    // setter that both stores the value AND updates the label, you let
    // Swift store the value automatically and just react *after* it
    // changes. This means anywhere in the codebase you can simply write
    // `coordinatePanel.latitude = 45.5` and the label updates itself —
    // the caller doesn't need to remember to also update the UI. Compare
    // this to UIRouteInfoPanel's `distanceText`/`durationText`, which use
    // the exact same pattern.
    public var latitude : Double = 0 {
        didSet{
            self.lblLatitude.text = String(format: "%.6f", latitude)
        }
    }

    public var longitude : Double = 0 {
        didSet{
            self.lblLongitude.text = String(format: "%.6f", longitude)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func initialize() {
        
        // Remember that we will apply constraints programmatically.
        // So, by default, let's turn off self.translateAutoresizingMaskIntoContraints
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.backgroundColor = .white.withAlphaComponent(0.7)
        
        
        self.addSubviews(lblLatitudeTitle, lblLongitudeTitle, lblLatitude, lblLongitude, imgPosition)
        

        self.imgPosition.enableTapGestureRecognizer(target: self, action: #selector(imgPositionTapped))
        
        applyConstraints()
                
    }
    
    
    @objc private func imgPositionTapped() {

        // 3. Calling the function from our delegate, assigning the
        // parameters.
        if (self.delegate != nil) {
            self.delegate!.coordinatePanelButtonTapped(self)
        }
        
    }
    
    private func applyConstraints() {
        
        lblLatitudeTitle.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        lblLatitudeTitle.topAnchor.constraint(equalTo: self.topAnchor, constant:  10).isActive = true
        lblLatitudeTitle.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5, constant: -10).isActive = true
        lblLatitudeTitle.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        
        lblLongitudeTitle.leadingAnchor.constraint(equalTo: lblLatitudeTitle.trailingAnchor).isActive = true
        lblLongitudeTitle.topAnchor.constraint(equalTo: lblLatitudeTitle.topAnchor).isActive = true
        lblLongitudeTitle.widthAnchor.constraint(equalTo: lblLatitudeTitle.widthAnchor).isActive = true
        lblLongitudeTitle.heightAnchor.constraint(equalTo: lblLatitudeTitle.heightAnchor).isActive = true
        
        lblLatitude.leadingAnchor.constraint(equalTo: lblLatitudeTitle.leadingAnchor).isActive = true
        lblLatitude.topAnchor.constraint(equalTo: lblLatitudeTitle.bottomAnchor).isActive = true
        lblLatitude.heightAnchor.constraint(equalTo: lblLatitudeTitle.heightAnchor).isActive = true
        lblLatitude.widthAnchor.constraint(equalTo: lblLatitudeTitle.widthAnchor).isActive = true
        
        lblLongitude.leadingAnchor.constraint(equalTo: lblLatitude.trailingAnchor).isActive = true
        lblLongitude.topAnchor.constraint(equalTo: lblLatitude.topAnchor).isActive = true
        lblLongitude.widthAnchor.constraint(equalTo: lblLatitude.widthAnchor).isActive = true
        lblLongitude.heightAnchor.constraint(equalTo: lblLatitude.heightAnchor).isActive = true
        
        
        imgPosition.widthAnchor.constraint(equalToConstant: 40).isActive = true
        imgPosition.heightAnchor.constraint(equalTo: imgPosition.widthAnchor).isActive = true
        imgPosition.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        imgPosition.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        
    }
    
}
