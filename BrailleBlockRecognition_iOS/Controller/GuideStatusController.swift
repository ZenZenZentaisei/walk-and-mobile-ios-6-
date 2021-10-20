class GuideStatusController {
    private let mp3Player = GuideStatusModel(message: "認識中")
    public var guideText = "認識中"
    var safariURL: URL?
    
    public func reflectImageProcessing(url: URL, message: String, call: String) {
        if mp3Player.process { return }
        mp3Player.process = true
        mp3Player.startMP3Player(mp3URL: url, completion: { initText in
            // 案内文を初期化
            self.guideText = initText
            self.mp3Player.process = false
            guard let webURL = NSURL(string: message) as URL? else { return }
            self.safariURL = webURL
            self.mp3Player.process = true
        })
        
        // 案内文を更新
        if message.prefix(4) == "http" {
            guideText = call
        } else {
            guideText = message
        }
    }
}
