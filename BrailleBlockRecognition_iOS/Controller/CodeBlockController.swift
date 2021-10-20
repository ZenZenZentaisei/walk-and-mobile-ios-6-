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
    
    var safariURL: URL?
    private let status = GuideStatusModel()
    public var guideText = "認識中"
    
    public func reflectImageProcessing(url: URL, message: String, call: String) {
        if status.process { return }
        
        status.process = true
        status.startMP3Player(mp3URL: url, completion: { initText in
            // 案内文を初期化
            self.guideText = initText
            guard let webURL = NSURL(string: message) as URL? else { return }
            self.safariURL = webURL
            self.status.process = true
        })
        
        // 案内文を更新
        if message.prefix(4) == "http" {
            guideText = call
        } else {
            guideText = message
        }
    }
    
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
