enum TypeInfo {
    case guidance
    case streaming
    case call
}

// Safari 関連ここかな
class CodeBlockController {
    private var guidanceMessage: [String: String] = [:]
    private var streamingURL: [String: String] = [:]
    private var callMessage: [String: String] = [:]
    
    public func fetchGuideInformation() {
        let modelCodeBlockInfo = CodeBlockInfoModel()
        let url = URL(string: "http://18.224.144.136/tenji/get_db2json.py?data=blockmessage")!
        modelCodeBlockInfo.responseCodeBlockServer(request: url, completion: { guide, streaming, call in
            self.guidanceMessage = guide
            self.streamingURL = streaming
            self.callMessage = call
        })
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
