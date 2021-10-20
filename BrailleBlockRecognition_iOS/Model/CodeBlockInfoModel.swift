class CodeBlockInfoModel {
    public func responseCodeBlockServer(request: URL, completion: @escaping ([String: String], [String: String], [String: String]) -> Void) {
        var dstMessage: [String: String] = [:]
        var dstWav: [String: String] = [:]
        var dstReading: [String: String] = [:]
        
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
}
