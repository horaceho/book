//
//  Book.swift
//  Zoom
//
//  Created by Horace Ho on 28/10/2022.
//

import UIKit

struct Book: Codable {
    var code: String
    var name: String
    var path: URL?
    var count: Int = 0
    var index: Int = 0
    var mode: Int = 0
    var point: CGPoint = CGPointZero // of PDFDestination
    var zoom: CGFloat = 1.0 // of PDFDestination
    var rect: CGRect = CGRectZero
    var auto: Bool = true
    var scale: CGFloat = 1.0
    var tofit: CGFloat = 1.0
}
