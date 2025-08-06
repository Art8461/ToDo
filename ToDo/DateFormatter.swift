//
//  DateFormatter.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 05.08.2025.
//

import Foundation

extension DateFormatter {
    static let sharedDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
}
