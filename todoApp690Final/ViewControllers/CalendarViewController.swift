import UIKit
import FSCalendar
import CoreData

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UITableViewDelegate, UITableViewDataSource {
    
    var calendar: FSCalendar!
    var dateFormatter = DateFormatter()
    var resultsController: NSFetchedResultsController<TaskEntity>!
    var coreDataStack = CoreDataStack()
    var tableView: UITableView!
    var hiddenRows: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendar = FSCalendar(frame: CGRect(x: 0.0, y: 88.0, width: self.view.frame.size.width, height: 300.0))
        tableView = UITableView(frame: CGRect(x: 0.0, y: calendar.frame.height+100.0, width: self.view.frame.size.width, height: self.view.frame.size.height-400.0))
        
        self.view.addSubview(calendar)
        self.view.addSubview(tableView)
        
        tableView.tableFooterView = UIView()
        
        calendar.dataSource = self
        calendar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        calendar.appearance.todayColor = UIColor(red: 241/255, green: 156/255, blue: 121/255, alpha: 0.3)
        calendar.appearance.titleTodayColor = .black
        calendar.appearance.titleDefaultColor = .black
        calendar.appearance.headerTitleColor = .black
        calendar.appearance.weekdayTextColor = .black
        calendar.appearance.eventDefaultColor = .black
        calendar.appearance.selectionColor = UIColor(red: 241/255, green: 156/255, blue: 121/255, alpha: 1)
        
        tableView.register(UINib(nibName: "CalendarCell", bundle: nil), forCellReuseIdentifier: "CalendarCell")
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let sortDescriptorDate = NSSortDescriptor(key: "taskDueDate", ascending: true)
        let sortDescriptorComplete = NSSortDescriptor(key: "taskIsComplete", ascending: true)
        request.sortDescriptors = [sortDescriptorDate, sortDescriptorComplete]
        
        resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try resultsController.performFetch()
        } catch {
            print("Perform fetch error: \(error)")
        }
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        dateFormatter.dateFormat = "MMM dd, yyyy"
        print("date selected: \(dateFormatter.string(from: date))")
        
        tableView.reloadData()
    }
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        return Date()
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        for task in resultsController.fetchedObjects! as [TaskEntity] {
            if (!task.taskIsComplete) {
                guard let eventDate = dateFormatter.date(from: dateFormatter.string(from: task.taskDueDate!)) else {return 0}
                if date.compare(eventDate) == .orderedSame {
                    return 1
                }
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].objects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let taskTypeString: [String] = ["Homework", "Quiz", "Exam", "Project", "Personal"]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarCell", for: indexPath)
        
        let currentTask = resultsController.object(at: indexPath)
        
        let todayDate = Date()
        
        if (calendar.selectedDate != nil) {
            let taskDueDate = dateFormatter.date(from: dateFormatter.string(from: currentTask.taskDueDate!))
            if (taskDueDate!.compare(calendar.selectedDate!) == .orderedSame) && !(currentTask.taskIsComplete) {
                cell.textLabel?.text = currentTask.taskTitle
                cell.detailTextLabel?.text = taskTypeString[Int(currentTask.taskType)]
                return cell
            }
            else {
                hiddenRows.append(indexPath.row)
                cell.isHidden = true
                return cell
            }
        } else {
            if (currentTask.taskDueDate?.compare(todayDate) == .orderedSame) && !(currentTask.taskIsComplete) {
                cell.textLabel?.text = currentTask.taskTitle
                cell.detailTextLabel?.text = taskTypeString[Int(currentTask.taskType)]
                return cell
            }
            else {
                hiddenRows.append(indexPath.row)
                cell.isHidden = true
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight: CGFloat = 0.0
        
        for row in hiddenRows {
            if (indexPath.row == row) {
                rowHeight = 0
            } else {
                rowHeight = 55.0
            }
        }
        return rowHeight
    }
}
