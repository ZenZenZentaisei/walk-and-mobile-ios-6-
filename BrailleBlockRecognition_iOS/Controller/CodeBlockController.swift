import Network

enum TypeInfo {
    case guidance
    case streaming
    case call
}

class CodeBlockController {
    private var guidanceMessage: [String: String] = [:]
    private var streamingURL: [String: String] = [:]
    private var callMessage: [String: String] = [:]
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.networkconfig")
    
    private var url = URL(string: "http://18.224.144.136/tenji/get_db2json.py?data=blockmessage")!
    
    public func fetchGuideInformation() {
        networkMonitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Connected")
                let globalDataBase = CodeBlockInfoModel()
                globalDataBase.responseCodeBlockServer(request: self.url, completion: { guide, streaming, call in
                    self.guidanceMessage = guide
                    self.streamingURL = streaming
                    self.callMessage = call
                })
            } else {
                print("Not Connected")
            }
        }
        networkMonitor.start(queue: queue)
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
    
    public func resultAllInfomation(type: TypeInfo) -> [String: String] {
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
