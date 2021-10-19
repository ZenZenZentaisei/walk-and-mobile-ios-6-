class CodeBlockInfoModel {
    var guidanceMessage: [String: String] = [:]
    var voice: [String: String] = [:]
    var callMessage: [String: String] = [:]
    
    let url = URL(string: "http://18.224.144.136/tenji/get_db2json.py?data=blockmessage")!
    
    func fetchBlockInfo() {
        let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            do{
                let Data_I = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! [NSDictionary]
    
                for data in Data_I{
                    let code = data.value(forKey: "code") as! Int
                    let angle = data.value(forKey: "angle") as! Int
                    let message = data.value(forKey: "message") as! String
                    let wav = data.value(forKey: "wav") as? String
                    let reading = data.value(forKey: "reading") as? String
                    
                    let dataKey = String(code) + String(angle)

                    self.guidanceMessage[dataKey] = message
                    self.voice[dataKey] = wav
                    self.callMessage[dataKey] = reading
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }
}
