import AVFoundation

class GuideStatusModel: NSObject {
    var audioPlayer: AVAudioPlayer
    var process: Bool
    let initMessage: String
    
    init(message: String) {
        audioPlayer = AVAudioPlayer()
        process = false
        initMessage = message
    }
    
    // 案内文を再生する
    public func startMP3Player(mp3URL: URL, completion: @escaping (String) -> Void) {
        let playbackSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        
        // 認識開始の効果音再生
        let openStartFile = "GeneralStart"
        let delayStartTime = durationEffectSound(fileName: openStartFile)
        playMP3File(url: fetchMP3File(file: openStartFile))
        
        // 案内文再生
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStartTime / Double(playbackSpeed)) {
            self.playStreamingMusic(url: mp3URL, completion: { streamURL in
                self.playMP3File(url: streamURL)
            })
        }
    
        // 認識終了の効果音再生
        let openFinishFile = "GeneralFinish"
        durationEndEffectSound(url: mp3URL, completion: { playbackTime in
            DispatchQueue.main.asyncAfter(deadline: .now() + (delayStartTime + playbackTime) / Double(playbackSpeed)) {
                if self.process != true { return }
                self.playMP3File(url: self.fetchMP3File(file: openFinishFile))
                self.process = false
                completion(self.initMessage)
            }
        })
        process = true
    }
    
    // 案内文を終了する
    public func stopMP3File() -> String {
        audioPlayer.stop()
        process = false
        return initMessage
    }
    
    // ローカル内のファイルを取得
    private func fetchMP3File(file: String) -> URL {
        guard let startedPath = Bundle.main.path(forResource: file, ofType: "mp3") else {
            fatalError("Cannot find mp3 file: GuidanceTextHasStartedPlaying")
        }
        return URL(fileURLWithPath: startedPath)
    }
    
    // 効果音(MP3)の再生時間を取得
    private func durationEffectSound(fileName: String) -> Double {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fetchMP3File(file: fileName))
        } catch {
            fatalError("Error \(error.localizedDescription)")
        }
    
        let effectDuration = Int(audioPlayer.duration)
        // 時間と分を計算
        let min = effectDuration / 60
        let sec = effectDuration % 60
        // 誤差
        let timeError = 0.1
        return Double(min * 60 + sec) + timeError
    }
    
    // ストリーミング再生している案内文の再生時間を取得
    private func durationEndEffectSound(url: URL, completion: @escaping (_ playbackTaime: Double) -> Void) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: URL!)
            } catch {
                fatalError("Error \(error.localizedDescription)")
            }
            // 誤差(何故か再生時間をストリーミングで取得すると-2秒になるため....)
            let timeError = 2.0
            completion(TimeInterval(ceil(Double(self.audioPlayer.duration))) + timeError)
        }
        downloadTask.resume()
    }
    
    // ストリーミンング形式で音(案内分)を再生
    private func playStreamingMusic(url: URL, completion: @escaping (URL) -> Void) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            completion(URL!)
        }
        downloadTask.resume()
    }
}

extension GuideStatusModel: AVAudioPlayerDelegate {
    func playMP3File(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            audioPlayer.enableRate = true
            audioPlayer.rate = UserDefaults.standard.float(forKey: "reproductionSpeed")
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("aaaaaaa")
//        guard let webView = safariVC else { return }
//        print("bbbbbbb")
//        if openSafariVC { return }
//        print("ccccccccc")
//        webView.delegate = self
//        present(webView, animated: true, completion: nil)
    }
}
