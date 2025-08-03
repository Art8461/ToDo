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

    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = todo?.name
        descriptionTextView.text = todo?.description
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else { return }

        let updated = todo ?? ToDo(name: name, isCompleted: false)
        updated.name = name
        updated.description = descriptionTextView.text

        onSave?(updated)
        navigationController?.popViewController(animated: true)
    }
}
