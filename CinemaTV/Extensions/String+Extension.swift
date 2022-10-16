//
//  String+Extension.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/10/22.
//

import Foundation

extension String {

    func formatString() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "yyyy-MM-dd"

        //first, convert string to Date
        let dt = fmt.date(from: self)!

        //then convert Date back to String in a different format
        fmt.dateFormat = "dd/MM/yyyy"
        return fmt.string(from: dt)
    }
}

extension Date {

    func toString(withFormat format: String = "EEEE ، d MMMM yyyy") -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = Locale.current.timeZone
        dateFormatter.calendar = Calendar.current
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)

        return str
    }
}
