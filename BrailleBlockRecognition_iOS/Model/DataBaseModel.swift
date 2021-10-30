import UIKit
import CoreData

class DataBaseModel {
    public static let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    public let managedContext = persistentContainer.viewContext
    
    public func responseCodeBlockServer(request: URL, completion: @escaping ([String: String],CodeDict,CodeDict) -> Void) {
        var dstMessage:CodeDict = [:]
        var dstWav:CodeDict = [:]
        var dstReading:CodeDict = [:]
        
        let task: URLSessionTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            do{
                let responseAllData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! [NSDictionary]
    
                for data in responseAllData {
                    let srcCode = data.value(forKey: "code") as! Int
                    let srcAngle = data.value(forKey: "angle") as! Int
                    let srcMessage = data.value(forKey: "message") as! String
                    let srcWav = data.value(forKey: "wav") as? String
                    let srcReading = data.value(forKey: "reading") as? String
                    
                    let dataKey = String(srcCode) + String(srcAngle)

                    dstMessage[dataKey] = srcMessage
                    dstWav[dataKey] = srcWav
                    dstReading[dataKey] = srcReading
                }
            } catch {
                print(error)
            }
            completion(dstMessage, dstWav, dstReading)
        })
        task.resume()
    }
    
    public func fetchAllData() -> (CodeDict, CodeDict) {
        var code: [NSInteger] = []
        var angle: [NSInteger] = []
        var message: [NSString] = []
        var reading: [NSString] = []
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CodeBlock")
        do {
            let myResults = try managedContext.fetch(fetchRequest)

            for myData in myResults {
                code.append(myData.value(forKey: "code") as! NSInteger)
                angle.append(myData.value(forKey: "angle") as! NSInteger)
                message.append(myData.value(forKey: "message") as! NSString)
                reading.append(myData.value(forKey: "reading") as! NSString)
            }

        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
        }
        
        return replaceValueInfo(data: (code, angle, message, reading))
    }
    
    private func replaceValueInfo(data: (Array<Int>, Array<Int>, Array<NSString>, Array<NSString>))  -> (CodeDict, CodeDict) {
        var argGuidance: CodeDict = [:]
        var argCall: CodeDict = [:]
        
        for i in 0..<data.0.count {
            let key = "\(data.0[i])" + "\(data.1[i])"
            argGuidance.updateValue(String(data.2[i]), forKey: key)
            argCall.updateValue(String(data.3[i]), forKey: key)
        }

        return (argGuidance, argCall)
    }
    
        
    public func saveAllData(guidace:CodeDict, call:CodeDict) {
        clearAllData()
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
    
    private func clearAllData() {
        let entities = DataBaseModel.persistentContainer.managedObjectModel.entities
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
