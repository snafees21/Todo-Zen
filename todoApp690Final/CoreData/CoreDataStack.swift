import Foundation
import CoreData

class CoreDataStack {
    var container : NSPersistentContainer {
        let container = NSPersistentContainer(name: "Tasks")
        container.loadPersistentStores { (description, error) in
            guard error == nil else {
                print("Error: \(error!)")
                return
            }
        }
        return container
    }
    
    var managedContext: NSManagedObjectContext {
        return container.viewContext
    }
}
