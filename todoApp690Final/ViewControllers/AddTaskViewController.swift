import UIKit
import CoreData

public extension NSManagedObject {
  convenience init(using usedContext: NSManagedObjectContext) {
    let name = String(describing: type(of: self))
    let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
    self.init(entity: entity, insertInto: usedContext)
  }
}

class AddTaskViewController: UIViewController {
    
    var managedContext: NSManagedObjectContext!

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var typeSegControl: UISegmentedControl!
    @IBOutlet weak var addTaskButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        titleTextField.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(with notification: Notification) {
        
        guard let keyboardFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        bottomConstraint.constant = keyboardHeight + 16
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
     
    @IBAction func addTaskPressed(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty else {
            return
        }
        
        let newTask = TaskEntity(using: managedContext)
        newTask.taskTitle = titleTextField.text
        
        newTask.taskType = Int16(typeSegControl.selectedSegmentIndex)
        newTask.taskDueDate = dueDatePicker.date
        newTask.taskIsComplete = false
        
        do {
            try managedContext.save()
            dismiss(animated: true)
            titleTextField.resignFirstResponder()

        } catch {
            print("Error saving task: \(error)")
        }
    }
}

