import AVFoundation

protocol AudioPlayerDelegate: AnyObject {
    func didFinshPlaying()
}

class AudioPlayerModel: NSObject {
    weak var delegate: AudioPlayerDelegate?
    
    private var audioPlayer = AVAudioPlayer()
    private let textToSpeech = AVSpeechSynthesizer()
    private let initMessage = "認識中"
    public var process = false
    
    // 案内文を再生する
    public func startMP3Player(mp3URL: URL, completion: @escaping (String) -> Void) {
        let playbackSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        
        // 認識開始の効果音再生
        let openStartFile = "GeneralStart"
        let delayStartTime = durationEffectSound(fileName: openStartFile)
        playSoundEffect(url: fetchMP3File(file: openStartFile))
        
        // 案内文再生
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStartTime / Double(playbackSpeed)) {
            self.playStreamingMusic(url: mp3URL, completion: { globalMP3, playbackTime  in
                self.playMP3File(url: globalMP3, speed: playbackSpeed)
                Thread.sleep(forTimeInterval: (delayStartTime + playbackTime) / Double(playbackSpeed))
                completion(self.initMessage)
            })
        }
        process = true
    }
    
    public func local(manuscript: String) {
        textToSpeech.delegate = self
        let read = AVSpeechUtterance(string: manuscript)
        read.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        textToSpeech.speak(read)
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
    
    // ストリーミンング形式で音(案内分)を再生
    private func playStreamingMusic(url: URL, completion: @escaping (URL, Double) -> Void) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: URL!)
            } catch {
                fatalError("Error \(error.localizedDescription)")
            }
            // 誤差(何故か再生時間をストリーミングで取得すると-2秒になるため....)
            let timeError = 2.0
            completion(URL!, TimeInterval(ceil(Double(self.audioPlayer.duration))) + timeError)
        }
        downloadTask.resume()
    }
}

extension AudioPlayerModel: AVAudioPlayerDelegate {
    func playSoundEffect(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            audioPlayer.delegate = self
            audioPlayer.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func playMP3File(url: URL, speed: Float) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            audioPlayer.enableRate = true
            audioPlayer.rate = speed
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
        delegate?.didFinshPlaying()
    }
}

extension AudioPlayerModel: AVSpeechSynthesizerDelegate {
    // 読み上げ終了
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        process = false
    }
}
