//
//  ToDo.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 03.08.2025.
//
import Foundation

class ToDo {
    var name: String
    var isCompleted: Bool
    var id: UUID
    var descriptionToDo: String?
    var date: Date
    var userId: Int?
    
    init(name: String, isCompleted: Bool, id: UUID=UUID(),description: String? = nil, date: Date = Date(), userId: Int? = nil) {
        self.name = name
        self.isCompleted = isCompleted
        self.id = id
        self.descriptionToDo = description
        self.date = date
        self.userId = userId
    }
}
