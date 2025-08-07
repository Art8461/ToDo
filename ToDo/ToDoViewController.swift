//
//  ToDoViewController.swift
//  ToDo
//
//  Created by Artem Kuzmenko on 03.08.2025.
//

import UIKit
import CoreData

class ToDoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, toDoCellDelegate {
    
    // MARK: - Properties
    
    var todos: [ToDo] = []
    var filteredTodos: [ToDo] = []
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
        fetchTasks()
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
    
    
    // MARK: - Actions
    
    @IBAction func AddToDo(_ sender: Any) {
        let alert = UIAlertController(title: "Создать ToDo", message: "", preferredStyle: .alert)
        alert.addTextField()
        
        let cancelButton = UIAlertAction(title: "Отмена", style: .destructive)
        alert.addAction(cancelButton)
        
        let saveButton = UIAlertAction(title: "Сохранить", style: .default) { _ in
            if let textName = alert.textFields?.first?.text {
                let now = Date()
                let newId = UUID()
                let newToDo = ToDo(name: textName, isCompleted: false, id: newId, description: nil, date: now)
                
                self.todos.append(newToDo)
                self.tableView.reloadData()
                self.updateTaskCount()
                
                self.saveTask(name: textName, isCompleted: false, id: newId, description: nil, date: now)
                self.fetchTasks()
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
        return isSearching ? filteredTodos.count : todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath) as? ToDoTableViewCell else {
            return UITableViewCell()
        }
        
        let todoCell = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
        cell.delegate = self
        cell.updateCell(with: todoCell)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedToDo = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
        performSegue(withIdentifier: "showEdit", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - toDoCellDelegate
    
    func cellTapped(cell: ToDoTableViewCell) {
        guard let index = tableView.indexPath(for: cell) else { return }
        
        let toDo = isSearching ? filteredTodos[index.row] : todos[index.row]
        let newValue = !toDo.isCompleted
        
        if isSearching {
            if let originalIndex = todos.firstIndex(where: { $0.id == toDo.id }) {
                todos[originalIndex].isCompleted = newValue
                updateTaskInCoreData(updatedToDo: todos[originalIndex])
            }
            filteredTodos[index.row].isCompleted = newValue
        } else {
            todos[index.row].isCompleted = newValue
            updateTaskInCoreData(updatedToDo: todos[index.row])
        }
        
        tableView.reloadRows(at: [index], with: .automatic)
    }
    
    func shareTask(cell: ToDoTableViewCell) {
        guard let index = tableView.indexPath(for: cell) else { return }
        let todo = isSearching ? filteredTodos[index.row] : todos[index.row]
        
        let textToShare = "Задача: \(todo.name)\nОписание: \(todo.descriptionToDo ?? "")"
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    func deleteTask(cell: ToDoTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let toDo = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
        
        deleteTaskFromCoreData(id: toDo.id)
        
        if isSearching {
            if let originalIndex = todos.firstIndex(where: { $0.id == toDo.id }) {
                todos.remove(at: originalIndex)
            }
            filteredTodos.remove(at: indexPath.row)
        } else {
            todos.remove(at: indexPath.row)
        }
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        updateTaskCount()
    }
    
    func editTask(cell: ToDoTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let task = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
            selectedToDo = task
            performSegue(withIdentifier: "showEdit", sender: self)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEdit",
           let destination = segue.destination as? EditToDoViewController,
           let toDo = selectedToDo,
           let index = todos.firstIndex(where: { $0.id == toDo.id }) {
            
            destination.todo = toDo
            destination.onSave = { [weak self] updatedToDo in
                self?.todos[index] = updatedToDo
                self?.updateTaskInCoreData(updatedToDo: updatedToDo)
                self?.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }
        
        isSearching = true
        filteredTodos = todos.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            ($0.descriptionToDo?.lowercased().contains(searchText.lowercased()) ?? false)
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    
    // MARK: - Task Count
    
    func updateTaskCount() {
        let total = todos.count
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
    
    func fetchTasks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        
        do {
            let coreDataTasks = try context.fetch(fetchRequest)
            todos = coreDataTasks.map { object in
                ToDo(
                    name: object.value(forKey: "name") as? String ?? "",
                    isCompleted: object.value(forKey: "isCompleted") as? Bool ?? false,
                    id: object.value(forKey: "newId") as? UUID ?? UUID(),
                    description: object.value(forKey: "descriptionToDo") as? String,
                    date: object.value(forKey: "dateToDo") as? Date ?? Date(),
                    userId: object.value(forKey: "userId") as? Int
                )
            }
        } catch {
            print("❌ Ошибка при загрузке: \(error)")
        }
    }
    
    func updateTaskInCoreData(updatedToDo: ToDo) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "newId == %@", updatedToDo.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existingTask = results.first {
                existingTask.setValue(updatedToDo.name, forKey: "name")
                existingTask.setValue(updatedToDo.descriptionToDo, forKey: "descriptionToDo")
                existingTask.setValue(updatedToDo.isCompleted, forKey: "isCompleted")
                existingTask.setValue(updatedToDo.date, forKey: "dateToDo")
                existingTask.setValue(updatedToDo.userId, forKey: "userId")
                try context.save()
            }
        } catch {
            print("❌ Ошибка при обновлении: \(error)")
        }
    }
    
    func deleteTaskFromCoreData(id: UUID) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "newId == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let taskToDelete = results.first {
                context.delete(taskToDelete)
                try context.save()
            }
        } catch {
            print("❌ Ошибка при удалении: \(error)")
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
                    let todosFromAPI = decoded.todos.map { apiTodo -> ToDo in
                        return ToDo(name: apiTodo.todo,
                                    isCompleted: apiTodo.completed,
                                    id: UUID(),
                                    date: Date(),
                                    userId: apiTodo.userId)
                    }
                    
                    DispatchQueue.main.async {
                        self.todos.append(contentsOf: todosFromAPI)
                        self.tableView.reloadData()
                        self.updateTaskCount()
                        
                        for todo in todosFromAPI {
                            self.saveTask(name: todo.name,
                                          isCompleted: todo.isCompleted,
                                          id: todo.id,
                                          description: todo.descriptionToDo,
                                          date: todo.date,
                                          userId: todo.userId)
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
