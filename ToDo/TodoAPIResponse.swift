//
//  TodoAPIResponse.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 06.08.2025.
//


// TodoAPIModel.swift
import Foundation

struct TodoAPIResponse: Codable {
    let todos: [TodoItem]
}

struct TodoItem: Codable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}
