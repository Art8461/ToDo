//
//  TaskDetailViewController.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 04.08.2025.
//

import Foundation
import UIKit

import UIKit

class EditToDoViewController: UIViewController {
    var todo: ToDo?
    var onSave: ((ToDo) -> Void)?
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var dateEdit: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = todo?.name
        descriptionTextView.text = todo?.descriptionToDo
        dateEdit.text = DateFormatter.sharedDisplayFormatter.string(from: todo?.date ?? Date())

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Проверяем, что пользователь нажал «назад», а не, например, показался алерт или другой экран
        if self.isMovingFromParent {
            if let updatedToDo = todo {
                updatedToDo.name = nameTextField.text ?? ""
                updatedToDo.descriptionToDo = descriptionTextView.text ?? ""
                onSave?(updatedToDo)
            }
        }
    }
}
