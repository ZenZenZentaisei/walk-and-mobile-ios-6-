import UIKit
import CoreData

class CoreDataModel {
    public static let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    public let managedContext = persistentContainer.viewContext
    
    public func fetchAllCoreData() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CodeBlock")
        var code : [NSInteger] = []
        do {
            let myResults = try managedContext.fetch(fetchRequest)

            for myData in myResults {
                code.append(myData.value(forKey: "code") as! NSInteger)
            }

        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
        }
        
        for i in code {
            print(i)
        }
    }
    
    public func saveAllCoreData(guidace: [String: String], call: [String: String]) {
        clearAllCoreData()
        for (key, value) in guidace {
            let code = key.prefix(key.count - 1)
            let angle = key.suffix(1)
            let message = value
            let reading = call[key] ?? "nil"
            
            let setData = CodeBlock(context: managedContext)
            setData.code = Int32(code) ?? 0
            setData.angle = Int16(angle) ?? 0
            setData.message = message
            setData.reading = reading
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    }
    
    private func clearAllCoreData() {
        let entities = CoreDataModel.persistentContainer.managedObjectModel.entities
        entities.compactMap({ $0.name }).forEach(clearDeepObjectEntity)
    }

    private func clearDeepObjectEntity(_ entity: String) {
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch {
            print ("There was an error")
        }
    }
}
