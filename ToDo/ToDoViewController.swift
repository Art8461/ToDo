//
//  ToDoViewController.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 03.08.2025.
//
import UIKit
import CoreData

class ToDoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, toDoCellDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    var fetchedResultsController: NSFetchedResultsController<NSManagedObject>!
    var selectedToDo: ToDo?
    var isSearching = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchToDo: UISearchBar!
    @IBOutlet weak var count: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupFetchedResultsController()
        updateTaskCount()
        
        if UserDefaults.standard.bool(forKey: "hasLoadedTasks") == false {
            loadTodosFromAPI()
        }
        
        setupGestureRecognizers()
    }
    
    // MARK: - Setup
    
    private func setupDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        searchToDo.delegate = self
    }
    
    private func setupGestureRecognizers() {
        for gesture in view.gestureRecognizers ?? [] {
            if let tapGesture = gesture as? UITapGestureRecognizer {
                tapGesture.cancelsTouchesInView = false
            }
        }
    }
    
    private func setupFetchedResultsController(searchText: String? = nil) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateToDo", ascending: true)]
        
        if let text = searchText, !text.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[c] %@ OR descriptionToDo CONTAINS[c] %@", text, text)
            isSearching = true
        } else {
            fetchRequest.predicate = nil
            isSearching = false
        }
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("❌ Ошибка при загрузке задач: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func AddToDo(_ sender: Any) {
        let alert = UIAlertController(title: "Создать ToDo", message: "", preferredStyle: .alert)
        alert.addTextField()
        
        let cancelButton = UIAlertAction(title: "Отмена", style: .destructive)
        alert.addAction(cancelButton)
        
        let saveButton = UIAlertAction(title: "Сохранить", style: .default) { _ in
            if let textName = alert.textFields?.first?.text, !textName.isEmpty {
                let now = Date()
                let newId = UUID()
                self.saveTask(name: textName, isCompleted: false, id: newId, description: nil, date: now)
                self.updateTaskCount()
            }
        }
        alert.addAction(saveButton)
        present(alert, animated: true)
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        view.endEditing(true)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath) as? ToDoTableViewCell else {
            return UITableViewCell()
        }
        
        let task = fetchedResultsController.object(at: indexPath)
        let todo = ToDo(
            name: task.value(forKey: "name") as? String ?? "",
            isCompleted: task.value(forKey: "isCompleted") as? Bool ?? false,
            id: task.value(forKey: "newId") as? UUID ?? UUID(),
            description: task.value(forKey: "descriptionToDo") as? String,
            date: task.value(forKey: "dateToDo") as? Date ?? Date(),
            userId: task.value(forKey: "userId") as? Int
        )
        cell.delegate = self
        cell.updateCell(with: todo)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = fetchedResultsController.object(at: indexPath)
        selectedToDo = ToDo(
            name: task.value(forKey: "name") as? String ?? "",
            isCompleted: task.value(forKey: "isCompleted") as? Bool ?? false,
            id: task.value(forKey: "newId") as? UUID ?? UUID(),
            description: task.value(forKey: "descriptionToDo") as? String,
            date: task.value(forKey: "dateToDo") as? Date ?? Date(),
            userId: task.value(forKey: "userId") as? Int
        )
        performSegue(withIdentifier: "showEdit", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - toDoCellDelegate
    
    // Статус задания
    
    func cellTapped(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = fetchedResultsController.object(at: indexPath)
        let newValue = !(task.value(forKey: "isCompleted") as? Bool ?? false)
        task.setValue(newValue, forKey: "isCompleted")
        
        do {
            try task.managedObjectContext?.save()
        } catch {
            print("❌ Ошибка при обновлении: \(error)")
        }
    }
    
    // Поделиться заданием
    
    func shareTask(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = fetchedResultsController.object(at: indexPath)
        let name = task.value(forKey: "name") as? String ?? ""
        let description = task.value(forKey: "descriptionToDo") as? String ?? ""
        
        let textToShare = "Задача: \(name)\nОписание: \(description)"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    // Удалить задание
    
    func deleteTask(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = fetchedResultsController.object(at: indexPath)
        
        task.managedObjectContext?.delete(task)
        do {
            try task.managedObjectContext?.save()
            updateTaskCount()
        } catch {
            print("❌ Ошибка при удалении: \(error)")
        }
    }
    
    // Редактировать задание
    
    func editTask(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let task = fetchedResultsController.object(at: indexPath)
        selectedToDo = ToDo(
            name: task.value(forKey: "name") as? String ?? "",
            isCompleted: task.value(forKey: "isCompleted") as? Bool ?? false,
            id: task.value(forKey: "newId") as? UUID ?? UUID(),
            description: task.value(forKey: "descriptionToDo") as? String,
            date: task.value(forKey: "dateToDo") as? Date ?? Date(),
            userId: task.value(forKey: "userId") as? Int
        )
        performSegue(withIdentifier: "showEdit", sender: self)
    }
    
    // MARK: - Navigation Переход к экрану редактирования
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEdit",
           let destination = segue.destination as? EditToDoViewController,
           let toDo = selectedToDo {
            
            destination.todo = toDo
            destination.onSave = { [weak self] updatedToDo in
                guard let self = self else { return }
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
                fetchRequest.predicate = NSPredicate(format: "newId == %@", updatedToDo.id as CVarArg)
                
                do {
                    let results = try self.fetchedResultsController.managedObjectContext.fetch(fetchRequest)
                    if let existingTask = results.first {
                        existingTask.setValue(updatedToDo.name, forKey: "name")
                        existingTask.setValue(updatedToDo.descriptionToDo, forKey: "descriptionToDo")
                        existingTask.setValue(updatedToDo.isCompleted, forKey: "isCompleted")
                        existingTask.setValue(updatedToDo.date, forKey: "dateToDo")
                        existingTask.setValue(updatedToDo.userId, forKey: "userId")
                        try existingTask.managedObjectContext?.save()
                    }
                } catch {
                    print("❌ Ошибка при обновлении: \(error)")
                }
            }
        }
    }
    
    // MARK: - UISearchBarDelegate Поисковик
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        setupFetchedResultsController(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setupFetchedResultsController()
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateTaskCount()
    }
    
    // MARK: - Task Count Общее количество задач
    
    func updateTaskCount() {
        let total = fetchedResultsController.fetchedObjects?.count ?? 0
        count.text = "\(total)"
    }
    
    // MARK: - Core Data Operations
    
    func saveTask(name: String, isCompleted: Bool, id: UUID, description: String? = nil, date: Date? = nil, userId: Int? = nil) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Task", in: context)!
        let newTask = NSManagedObject(entity: entity, insertInto: context)
        newTask.setValue(name, forKey: "name")
        newTask.setValue(isCompleted, forKey: "isCompleted")
        newTask.setValue(id, forKey: "newId")
        newTask.setValue(description, forKey: "descriptionToDo")
        newTask.setValue(date, forKey: "dateToDo")
        newTask.setValue(userId, forKey: "userId")
        
        do {
            try context.save()
        } catch {
            print("❌ Не удалось сохранить: \(error)")
        }
    }
    
    // MARK: - API Loading
    
    func loadTodosFromAPI() {
        guard let url = URL(string: "https://dummyjson.com/todos") else { return }
        
        DispatchQueue.global(qos: .background).async {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else { return }
                
                do {
                    let decoded = try JSONDecoder().decode(TodoAPIResponse.self, from: data)
                    DispatchQueue.main.async {
                        for apiTodo in decoded.todos {
                            self.saveTask(
                                name: apiTodo.todo,
                                isCompleted: apiTodo.completed,
                                id: UUID(),
                                date: Date(),
                                userId: apiTodo.userId
                            )
                        }
                        UserDefaults.standard.set(true, forKey: "hasLoadedTasks")
                    }
                } catch {
                    print("❌ Ошибка парсинга JSON: \(error)")
                }
            }.resume()
        }
    }
}
