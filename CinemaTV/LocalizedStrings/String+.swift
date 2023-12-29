//
//  String+.swift
//  CinemaTV
//
//  Created by Jessica Bigal on 24/09/22.
//

import Foundation

public extension String {
    enum LocalizedFeatureKind {
        case presentation
        case acessibility
    }
    
    var text: String {
        return localized(.presentation)
    }
    
    func localized(_ feature: LocalizedFeatureKind = .presentation)-> String {
        var fileName = String()
        
        switch feature {
        case .presentation:
            fileName = "Localizable"
        case .acessibility:
            fileName = "Localizable"
        }
        
        return NSLocalizedString(self, tableName: fileName, bundle: .moduleBundle, value: String(), comment: String())
    }
}
