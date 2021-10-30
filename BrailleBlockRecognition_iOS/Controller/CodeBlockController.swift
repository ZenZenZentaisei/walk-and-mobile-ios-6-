import Network

enum TypeInfo {
    case guidance
    case streaming
    case call
}

typealias CodeDict = [String: String]

class CodeBlockController {
    private var guidanceMessage:CodeDict = [:]
    private var streamingURL:CodeDict = [:]
    private var callMessage:CodeDict = [:]
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.networkconfig")
    
    private let database = DataBaseModel()
    
    public  let language = NSLocale.preferredLanguages.first?.components(separatedBy: "-").first 
    
    public func fetchGuideInformation() {
        networkMonitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Connected")
                let url = self.checkDeviceLocation()
                self.database.responseCodeBlockServer(request: url, completion: { guide, streaming, call in
                    self.guidanceMessage = guide
                    self.streamingURL = streaming
                    self.callMessage = call
                })
            } else {
                print("Not Connected")
                self.setLocalData(data: self.database.fetchAllData())
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    private func checkDeviceLocation() -> URL {
        let standard = "http://18.224.144.136/tenji/get_db2json.py?data=blockmessage"

        switch language {
        case "ja":
            return URL(string: standard)!
        case "en":
            return URL(string: standard + "_en")!
        case "ko":
            return URL(string: standard + "_ko")!
        case "zh":
            return URL(string: standard + "_zh")!
        default:
            return URL(string: standard)!
        }
    }
    
    private func setLocalData(data: (CodeDict, CodeDict)){
        guidanceMessage = data.0
        streamingURL = [:]
        callMessage = data.1
    }
    
    public func saveLocalDataBase() {
        database.saveAllData(guidace: guidanceMessage, call: callMessage)
    }
    
    public func resultValue(key: String, type: TypeInfo) -> String? {
        switch type {
        case .guidance:
            return guidanceMessage[key]
        case .streaming:
            return streamingURL[key]
        case .call:
            return callMessage[key]
        }
    }
    
    public func resultAllInfomation(type: TypeInfo) ->CodeDict {
        switch type {
        case .guidance:
            return guidanceMessage
        case .streaming:
            return streamingURL
        case .call:
            return callMessage
        }
    }
}
