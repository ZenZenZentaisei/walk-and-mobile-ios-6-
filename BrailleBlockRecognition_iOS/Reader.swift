import Foundation
import CoreData

var block:[BBlock] = []
let context = (UIApplication.shared.delegate as! AppDelegate)
var ManagedObjectContext = context.persistentContainer.viewContext
let blockFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BBlock")

let fetchRequest:NSFetchRequest<BBlock> = BBlock.fetchRequest()

class Reader{
    var userDefaults = UserDefaults.standard
    
    //jsonコードの取得　取得されなくても完了したらtrue、
    func httpGet() ->Bool{
        
        let semaphore = DispatchSemaphore(value: 0)
        
        self.resetAllRecords(in:"BBlock")
        let url: URL = URL(string: "http://ec2-3-136-168-45.us-east-2.compute.amazonaws.com/tenji/get_db2json.py?data=blockmessage")!
        let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            /*
            // コンソールに出力
            print("data: \(String(describing: data))")
            print("response: \(String(describing: response))")
            print("error: \(String(describing: error))")
            */
            do{
                let Data_I = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! [NSDictionary]
                
                for data in Data_I{
                    let newBlock = BBlock(context: ManagedObjectContext)
                    newBlock.id = data["id"] as! Int16
                    newBlock.code = data["code"] as! Int32
                    newBlock.angle = data["angle"] as! Int16
                    newBlock.message = data["message"] as! String
                    newBlock.messagecategory = data["messagecategory"] as! String
                    newBlock.reading = data["reading"] as? String
                    newBlock.mp3 = data["wav"] as? String
                    context.saveContext()
                }
            }
            catch {
                print(error)
            }
            semaphore.signal()
            
        })
        task.resume()
        
        semaphore.wait()
        print("end_DB")
        let  predicate = NSPredicate(format: "mp3.length > 0")
        fetchRequest.predicate = predicate
            
        let fetchData = try! ManagedObjectContext.fetch(fetchRequest)
        semaphore.signal()

        for i in 0..<fetchData.count{
            semaphore.wait()
            let mp3Data = (fetchData[i] as AnyObject).mp3! as String
            let mp3 = String(mp3Data.suffix(mp3Data.count - 8))
            Audio().writeAudio(mp3: mp3)
            print(mp3)
            semaphore.signal()
        }
        //semaphore.signal()
        
        //semaphore.wait()
        print("end_local")
        return true
    }
    
    func reader_IS(code:Int, angle:Int){
        var result :String
        //初回であれば、ユーザーデータベース("IS")作成
        if let _ = UserDefaults.standard.string(forKey: "IS"){
            result = self.userDefaults.string(forKey: "IS") as! String
        }
        else{
            result = ""
        }
        //URL作成
        let url = URL(string: "http://ec2-3-136-168-45.us-east-2.compute.amazonaws.com/tenji/get_message.py?code="
            + String(code) + "&angle=" + String(angle))!
        
        let fetchRequest:NSFetchRequest<BBlock> = BBlock.fetchRequest()
        //検索条件
        let predicate = NSPredicate(format: "code = %d and angle = %d and messagecategory = %@",code,angle,"normal")
        //let predicate = NSPredicate(format: "code = %ld and angle = %ld and messagecategory = %@",code,angle,"nomal")
        
        fetchRequest.predicate = predicate
        
        let fetchData = try! ManagedObjectContext.fetch(fetchRequest)
        if(!fetchData.isEmpty){
              for i in 0..<fetchData.count{
                self.userDefaults.set(fetchData[i].message, forKey: "IS")
              }
        }
        
        
        
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            do {
                result = String(data: data, encoding: .utf8)!
                self.userDefaults.set(result, forKey: "IS")
            } catch let e {
                print("JSON Decode Error :\(e)")
                fatalError()
            }
            
        }
        task.resume()
        return
    }
    
    func resetAllRecords(in entity : String) // entity = Your_Entity_Name
    {
        let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try context.execute(deleteRequest)
            try context.save()
        }
        catch
        {
            print ("There was an error")
        }
    }
}
