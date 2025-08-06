//
//  ToDoTableViewCell.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 03.08.2025.
//

import Foundation
import UIKit

protocol toDoCellDelegate: AnyObject {
    func cellTapped(cell: ToDoTableViewCell)
    func editTask(cell: ToDoTableViewCell)
    func shareTask(cell: ToDoTableViewCell)
    func deleteTask(cell: ToDoTableViewCell)
}
class ToDoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var toDoLabel: UILabel!
    @IBOutlet weak var toDoButton: UIButton!
    @IBOutlet weak var toDoDescriptionLabel: UILabel!
    @IBOutlet weak var toDoDate: UILabel!
    
    weak var delegate: toDoCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }

    
    func updateCell(with toDo: ToDo) {
        let attributes: [NSAttributedString.Key: Any] = toDo.isCompleted
            ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
            ]
            : [.strikethroughStyle: 0,
               .foregroundColor: UIColor.label
            ]
        
        // Название с зачеркиванием

        let attributedText = NSAttributedString(string: toDo.name, attributes: attributes)
        toDoLabel.attributedText = attributedText
        
        // Затемнение текста на 50% (opacity)

        let alpha: CGFloat = toDo.isCompleted ? 0.5 : 1.0
        toDoLabel.alpha = alpha
        toDoDescriptionLabel.alpha = alpha
        toDoDescriptionLabel.text = toDo.descriptionToDo?.isEmpty == false ? toDo.descriptionToDo : ""
        
        // Кнопка
        
        toDoButton.setImage(
            UIImage(systemName: toDo.isCompleted ? "checkmark.circle" : "circle"),
            for: .normal
        )
        
        // Дата
        toDoDate.text = DateFormatter.sharedDisplayFormatter.string(from: toDo.date)
        toDoDate.alpha = 0.5
    }
    @IBAction func toDoButtonTapped(_ sender: Any) {
        delegate?.cellTapped(cell: self)
    }
}

//AlertContextMenu

extension ToDoTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let editAction = UIAction(title: "Редактировать", image: UIImage(systemName: "pencil")) { _ in
                self.delegate?.editTask(cell: self)
            }
            let shareAction = UIAction(title: "Поделиться", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self.delegate?.shareTask(cell: self)
            }
            let deleteAction = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.delegate?.deleteTask(cell: self)
            }
            
            return UIMenu(title: "", children: [editAction, shareAction, deleteAction])
        }
    }
}
