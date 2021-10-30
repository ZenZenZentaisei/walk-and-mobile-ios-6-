import AVFoundation

protocol AudioPlayerDelegate: AnyObject {
    func didFinshPlaying()
    func didFinishReading()
}

class AudioPlayerModel: NSObject {
    weak var delegate: AudioPlayerDelegate?
    
    private var audioPlayer = AVAudioPlayer()
    private let textToSpeech = AVSpeechSynthesizer()
    private let initMessage = NSLocalizedString("Verification", comment: "")
    public var process = false
    
    private var playbackSpeed: Float = 0.0
    private var delayStartTime: Double = 0.0
    
    // 案内文を再生する
    public func onlineReadGuide(mp3URL: URL, completion: @escaping (String, Double) -> Void) {
        beginSoundEffect()

        // 案内文再生
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStartTime / Double(playbackSpeed)) {
            self.durationStreamingMusic(url: mp3URL, completion: { globalMP3, duration  in
                self.playMP3File(url: globalMP3, speed: self.playbackSpeed)
                completion(self.initMessage, (self.delayStartTime + duration) / Double(self.playbackSpeed))
            })
        }
    }
    
    public func offlineReadGuide(manuscript: String) {
        beginSoundEffect()
        
        textToSpeech.delegate = self
        let read = AVSpeechUtterance(string: manuscript)
        read.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        read.rate = 0.5
        
        // 案内文を読み上げ
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStartTime / Double(playbackSpeed)) {
            self.textToSpeech.speak(read)
        }
    }
    
    // 案内文を終了する
    public func stopMP3File() -> String {
        audioPlayer.stop()
        textToSpeech.stopSpeaking(at: .immediate)
        process = false
        return initMessage
    }
    
    // 認識開始の効果音再生
    private func beginSoundEffect() {
        let openStartFile = "GeneralStart"
        if UserDefaults.standard.float(forKey: "reproductionSpeed") != 0.0 {
            playbackSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        } else {
            playbackSpeed = 1.0
        }
        
        delayStartTime = durationEffectSound(fileName: openStartFile)
        playSoundEffect(url: fetchMP3File(file: openStartFile))
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
    private func durationStreamingMusic(url: URL, completion: @escaping (URL, Double) -> Void) {
        print(url)
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
        delegate?.didFinishReading()
    }
}
