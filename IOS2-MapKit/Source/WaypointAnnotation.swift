//
//  WaypointAnnotation.swift
//  IOS2-MapKit
//
//  Subclasă MKPointAnnotation care reține, pe lângă coordonată și titlu,
//  dacă pinul reprezintă destinația finală sau o oprire intermediară, și
//  al câtelea este în ordinea traseului. Folosită exclusiv pentru
//  stilizare — vezi mapView(_:viewFor:) din ViewController.swift, care
//  alege culoarea și glyph-ul pinului pe baza acestor două proprietăți.
//
//  TEORIE — de ce o subclasă, nu doar MKPointAnnotation simplu?
//  MKPointAnnotation de bază oferă doar coordonată, titlu și subtitlu —
//  nimic care să spună "sunt oprirea 2 din 4" sau "sunt destinația
//  finală". În loc să deducem asta din titlu (fragil — s-ar strica dacă
//  am schimba vreodată textul afișat), subclasificăm și adăugăm exact
//  informația de care avem nevoie, ca proprietăți proprii, tipate.
//

import MapKit

final class WaypointAnnotation: MKPointAnnotation {
    var isFinalDestination = false
    var stopNumber = 0
}
