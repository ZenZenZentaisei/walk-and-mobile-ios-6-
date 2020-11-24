import Foundation
import CoreData

var block:[BBlock] = []
let context = (UIApplication.shared.delegate as! AppDelegate)
var ManagedObjectContext = context.persistentContainer.viewContext
let blockFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BBlock")

let fetchRequest:NSFetchRequest<BBlock> = BBlock.fetchRequest()

class Reader{
    var userDefaults = UserDefaults.standard
    
    /*事前ダウンロード部(出力)
     true   :両方取得
     false  :案内情報のみ取得
     */
    func httpGet(GuideVoice :Bool) {
        var wait = true
        self.resetAllRecords(in:"BBlock")
        print("reset")
        let url: URL = URL(string: "http://ec2-3-136-168-45.us-east-2.compute.amazonaws.com/tenji/get_db2json.py?data=blockmessage")!
        let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            do{
                let Data_I = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! [NSDictionary]
                    
                //初回の呼び出しが重いので、for外に出してみる(クラッシュ対策)
                _ = BBlock(context: ManagedObjectContext)
                sleep(2)
                
                for data in Data_I{
                    
                    let newBlock = BBlock(context: ManagedObjectContext)
                    newBlock.id = data["id"] as! Int16
                    newBlock.code = data["code"] as! Int32
                    newBlock.angle = data["angle"] as! Int16
                    newBlock.message = (data["message"] as! String)
                    newBlock.messagecategory = (data["messagecategory"] as! String)
                    newBlock.reading = data["reading"] as? String
                    newBlock.mp3 = data["wav"] as? String
                    print(newBlock.id,newBlock.code,newBlock.angle)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        context.saveContext()
                    })
                }
                wait = false
            }
            catch {
                print(error)
            }
            
        })
        task.resume()
        
        //json読み込み待ち
        while(wait){}
        
        if(GuideVoice){
            //マルチスレッド開始
            OperationQueue().addOperation({ [self] () -> Void in
                
                let  predicate = NSPredicate(format: "mp3.length > 0")
                fetchRequest.predicate = predicate
                
                let fetchData = try! ManagedObjectContext.fetch(fetchRequest)
                
                let _ = userDefaults.integer(forKey: "nowdata")
                let _ = userDefaults.integer(forKey: "maxdata")
                let maxdata = Int(fetchData.count)
                self.userDefaults.set(maxdata, forKey: "maxdata")

                for i in 0..<fetchData.count{
                    let mp3Data = (fetchData[i] as AnyObject).mp3! as String
                    let mp3 = String(mp3Data.suffix(mp3Data.count - 8))
                    Audio().writeAudio(mp3: mp3)
                    print(mp3)
                    
                    self.userDefaults.set(i+1, forKey: "nowdata")
                    
                    print(String(i+1) + "/" + String(fetchData.count))
                }
                print("end_local")
                self.userDefaults.set(false, forKey: "dlwait")
            })
        }
        else{
            self.userDefaults.set(false, forKey: "dlwait")
        }
        return
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
        var wait = true
        let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try context.execute(deleteRequest)
            try context.save()
            
            wait = false
        }
        catch
        {
            print ("There was an error")
            
        }
        
        while(wait){}
    }
}
