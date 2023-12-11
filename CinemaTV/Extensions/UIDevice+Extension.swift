//
//  UIDevice+Extension.swift
//  CinemaTV
//
//  Created by Danilo Requena on 11/12/23.
//

import UIKit

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
