import UIKit
import CoreData

class TaskTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    let dateFormatter = DateFormatter()
    var resultsController: NSFetchedResultsController<TaskEntity>!
    let coreDataStack = CoreDataStack()
    var searchController: UISearchController!
    @IBOutlet var taskSearchBar: UISearchBar!
    var taskList: [NSManagedObject] = []
    var searchActive: Bool = false
    @IBOutlet var taskFilterButton: UIBarButtonItem!
    let todayDate = Date(timeIntervalSinceReferenceDate: 629326004)
    let quoteButton = UIButton(frame: CGRect(x: 300, y: 200, width: 75, height: 75))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "EEE, MMM d - hh:mm a"
        
        taskSearchBar.showsCancelButton = true
        taskSearchBar.delegate = self
        taskSearchBar.isTranslucent = true
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        let sortDescriptorType = NSSortDescriptor(key:"taskType", ascending: true)
        let sortDescriptorDate = NSSortDescriptor(key: "taskDueDate", ascending: true)
        let sortDescriptorComplete = NSSortDescriptor(key: "taskIsComplete", ascending: true)
        
        request.sortDescriptors = [sortDescriptorType, sortDescriptorDate, sortDescriptorComplete]
        
        resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: "taskType", cacheName: nil)
        resultsController.delegate = self
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        do {
            try resultsController.performFetch()
            taskList = try managedObjectContext.fetch(request) as [NSManagedObject]
        } catch {
            print("Perform fetch error: \(error)")
        }
        
        quoteButton.layer.cornerRadius = 0.5 * quoteButton.bounds.size.width
        quoteButton.clipsToBounds = true
        quoteButton.backgroundColor = UIColor(red: 212/255, green: 224/255, blue: 155/255, alpha: 1)
        quoteButton.setImage(UIImage(named: "lightIcon.png"), for: .normal)
        quoteButton.layer.borderWidth = 2
        quoteButton.layer.borderColor = UIColor.black.cgColor
        quoteButton.addTarget(self, action: #selector(self.quoteButtonClicked(sender:)), for: .touchUpInside)
        self.view.addSubview(quoteButton)
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        quoteButton.frame.origin.y = 700 + scrollView.contentOffset.y
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if taskSearchBar.searchTextField.isEditing {
            return 1
        } else {
            return self.resultsController.sections!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchActive {
            return ""
        } else {
            switch (section) {
            case 0: return "Homework"
            case 1: return "Quiz"
            case 2: return "Exam"
            case 3: return "Project"
            case 4: return "Personal"
            default: return ""
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if taskSearchBar.searchTextField.isEditing {
            return taskList.count
        } else {
            return self.resultsController.sections?[section].numberOfObjects ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let completedCell = tableView.dequeueReusableCell(withIdentifier: "CompletedTaskCell", for: indexPath)
        
        var currentTask = resultsController.object(at: indexPath)
        
        if searchActive {
            currentTask = taskList[indexPath.row] as! TaskEntity
        } else {
            currentTask = resultsController.object(at: indexPath)
        }
        
        if (currentTask.value(forKey: "taskIsComplete") as? Bool)! {
            completedCell.accessoryType = .checkmark
            completedCell.textLabel?.text = currentTask.value(forKey: "taskTitle") as? String
            return completedCell
        } else {
            cell.taskLabel?.text = currentTask.value(forKey: "taskTitle") as? String
            cell.dueLabel?.text = dateFormatter.string(from: (currentTask.value(forKey: "taskDueDate") as? Date)!)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentTask = resultsController.object(at: indexPath)
        
        if (!currentTask.taskIsComplete) {
            currentTask.taskIsComplete = true
        } else {
            currentTask.taskIsComplete = false
        }
        
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .fade)
        tableView.endUpdates()
        
        do {
            try self.resultsController.managedObjectContext.save()
        } catch {
            print("Update failed: \(error)")
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            
            let currentTask = self.resultsController.object(at: indexPath)
            self.resultsController.managedObjectContext.delete(currentTask)
            
            do {
                try self.resultsController.managedObjectContext.save()
                completion(true)
            } catch {
                print("Delete failed: \(error)")
                completion(false)
            }
        }
        action.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchActive = true
        if !searchText.isEmpty {
            var predicate: NSPredicate = NSPredicate()
            predicate = NSPredicate(format: "taskTitle contains[c] '\(searchText)'")
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"TaskEntity")
            fetchRequest.predicate = predicate
            do {
                taskList = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch. \(error)")
            }
        }
        tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.resignFirstResponder()
        searchBar.text = ""
        resultsController.fetchRequest.predicate = nil
        
        do {
            try resultsController.performFetch()
        } catch {
            print("error: \(error)")
        }
        
        tableView.reloadData()
    }
    
    @objc func quoteButtonClicked(sender: UIButton) {
        let quotes: [String] = ["Hello beautiful!!", "Smile, happiness looks gorgeous on you!", "Well, hello there.", "I haven't seen you in a while! Hello!", "Look at your sparkly eyes! They’re pretty!", "Give me that 100watt smile!", "Hope you’re having a great day!", "Sending you a warm hello! Hope today is a happy day for you.", "Why hello there! Didn’t see you come in!", "I’ve missed you! Welcome back friend!", "Well aren’t you a charming person!", "Make sure to get enough sleep for your health!"]
        let randomInt = Int.random(in: 0..<11)
        let randomQuote = quotes[randomInt]
        
        let quoteAlert = UIAlertController(title: randomQuote, message: nil, preferredStyle: .alert)
        let cancelAlert = UIAlertAction(title: "Thank you!", style: .cancel, handler: nil)
        quoteAlert.addAction(cancelAlert)
        quoteAlert.view.tintColor = UIColor(red: 36/255, green: 32/255, blue: 56/255, alpha: 1)
        
        present(quoteAlert, animated: true, completion: nil)
        
        let subview = (quoteAlert.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
        subview.backgroundColor = UIColor(red: 246/255, green: 244/255, blue: 210/255, alpha: 1)
    }
    
    // TODO:- needs to be debugged
    @IBAction func filterButtonPressed(_ sender: UIBarButtonItem) {

        let filterAlert = UIAlertController(title: "Show tasks from: ", message: nil, preferredStyle: .actionSheet)
        let filterToday = UIAlertAction(title: "Today", style: .default, handler: { _ in
            var predicate: NSPredicate = NSPredicate()
            predicate = self.todayDate.makeDatePredicate(days: 1)

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"TaskEntity")
            fetchRequest.predicate = predicate
            do {
                self.taskList = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch. \(error)")
            }
        self.tableView.reloadData()
        })
        
        let filterThisWeek = UIAlertAction(title: "This Week", style: .default, handler: { _ in
            var predicate: NSPredicate = NSPredicate()
            predicate = self.todayDate.makeDatePredicate(days: 7)

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"TaskEntity")
            fetchRequest.predicate = predicate
            do {
                self.taskList = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch. \(error)")
            }
        self.tableView.reloadData()
        })
        
        let filterThisMonth = UIAlertAction(title: "This Month", style: .default, handler: { _ in
            var predicate: NSPredicate = NSPredicate()
            predicate = self.todayDate.makeDatePredicate(days: 30)

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"TaskEntity")
            fetchRequest.predicate = predicate
            do {
                self.taskList = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch. \(error)")
            }
        self.tableView.reloadData()
        })
        
        let filterAll = UIAlertAction(title: "All", style: .cancel, handler: { _ in
            self.searchActive = false
            self.resultsController.fetchRequest.predicate = nil
            do {
                try self.resultsController.performFetch()
            } catch {
                print("error: \(error)")
            }
            
            self.tableView.reloadData()
        })
        
        filterAlert.addAction(filterToday)
        filterAlert.addAction(filterThisWeek)
        filterAlert.addAction(filterThisMonth)
        filterAlert.addAction(filterAll)
        
        present(filterAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let _ = sender as? UIBarButtonItem, let vc = segue.destination as? AddTaskViewController {
            vc.managedContext = resultsController.managedObjectContext
        }
    }
}

extension Date {
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    
    func makeDatePredicate(days: Int) -> NSPredicate {

        let calendar = Calendar.current
        
        let dateFrom = calendar.startOfDay(for: self)
        let dateTo = calendar.date(byAdding: .day, value: days, to: dateFrom)
        
        let fromPredicate = NSPredicate(format: "taskDueDate >= %@", dateFrom as NSDate)
        let toPredicate = NSPredicate(format: "taskDueDate < %@", dateTo! as NSDate)
        
        let datePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])
        return datePredicate
    }
    
    func asString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}


extension TaskTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let section = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(section, with: .fade)
            
        case .delete:
            tableView.deleteSections(section, with: .fade)
        default:
            break
        }
    }
}
