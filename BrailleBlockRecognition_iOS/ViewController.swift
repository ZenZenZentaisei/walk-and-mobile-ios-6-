import UIKit
import AVFoundation
import SafariServices

class ViewController: UIViewController {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var guidance: UITextView!
    
    var infoBarButtonItem: UIBarButtonItem!     // 編集ボタン
    
    let initGuidanceMessage = "認識中"
  
    var audioPlayer = AVAudioPlayer()
    
    var playingTheGuide = false
    var openSafariVC = false
    var safariVC: SFSafariViewController?

    
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    
    var session: AVCaptureSession! //セッション
    var device: AVCaptureDevice! //カメラ
    var output: AVCaptureVideoDataOutput! //出力先
    
    var configBool = false
    var stop_bool = false


    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        audioPlayer.stop()
        playingTheGuide = false
        guidance.text = initGuidanceMessage
    }
    //自動スリープを無効化
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      UIApplication.shared.isIdleTimerDisabled = true  // この行
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //音声データ格納用フォルダ作成
        Audio().createFolder(addFolder: "message")
        Audio().createFolder(addFolder: "message_en")
        initCamera()
       
        infoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .done, target: self, action: #selector(infoBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = infoBarButtonItem
        
        guidance.text = initGuidanceMessage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    
    @objc func infoBarButtonTapped(_ sender: UIBarButtonItem) {
        let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "infoVC") as! InfoViewController
        let nav = UINavigationController(rootViewController: secondViewController)
        self.present(nav, animated: true, completion: nil)
    }
    
    //値の送受信(設定画面)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let next = segue.destination as? Config
        //値を送信
        next?.configBool = configBool
        //値を受信
        next?.resultHandler = { setting in
        self.configBool = setting
        }
    }
    
    // sampleBufferからUIImageを作成
    func captureImage(_ sampleBuffer:CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)

        // ベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // 画像データの情報を取得
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!

        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)

        // RGB色空間を作成
        let colorSpace: CGColorSpace! = CGColorSpaceCreateDeviceRGB()

        // Bitmap graphic contextを作成
        let bitsPerCompornent: Int = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext: CGContext! = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) as CGContext?

        // Quartz imageを作成
        let imageRef: CGImage! = newContext!.makeImage()

        // ベースアドレスをアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // UIImageを作成
        let resultImage: UIImage = UIImage(cgImage: imageRef)

        return resultImage
    }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // カメラの準備処理
    func initCamera() {
        // セッションの作成.
        session = AVCaptureSession()
        // 解像度の指定.
        session.sessionPreset = .photo
        // デバイス取得.
        device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                         for: .video,
                                         position: .back)

        // VideoInputを取得.
        var input: AVCaptureDeviceInput! = nil
        do {
            input = try AVCaptureDeviceInput(device: device) as AVCaptureDeviceInput
        } catch let error {
            print(error)
            return
        }

        // セッションに追加.
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            return
        }

        // 出力先を設定
        output = AVCaptureVideoDataOutput()

        //ピクセルフォーマットを設定
        output.videoSettings =
            [ kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA) ]

        //サブスレッド用のシリアルキューを用意
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        // 遅れてきたフレームは無視する
        //怪しい
        output.alwaysDiscardsLateVideoFrames = true

        // FPSを設定
        do {
            try device.lockForConfiguration()

            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20) //フレームレート
            device.unlockForConfiguration()
        } catch {
            return
        }

        // セッションに追加.
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            return
        }

        // カメラの向きを合わせる
        for connection in output.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            let openCV = OpenCV()
            // 初期化(↓しないと何故か状態を保存し、更新されない)
            openCV.reader(UIImage(named: "sample"))! as NSArray
            
            let img = self.captureImage(sampleBuffer) //UIImageへ変換z
                
            let result = openCV.reader(img)! as NSArray
                
            let resultImg = result[0] as! UIImage
            let resultCode = result[1] as! Int
            let resultAngle = result[2] as! Int

            self.cameraImageView.image = resultImg
            
            if self.playingTheGuide { return }
            self.safariVC = self.reflectRecognition(angleRecognition: "\(resultCode)", codeRecognition: "\(resultAngle)")
        }
    }
    
    // 認識結果を画面に反映
    func reflectRecognition(angleRecognition: String, codeRecognition: String) -> SFSafariViewController? {
        let guidanceKey = angleRecognition + codeRecognition
        guard let loadURL = appDelegate.voice[guidanceKey] else { return nil }
        guard let mp3URL = URL(string: "http://18.224.144.136/tenji/" + loadURL) else { return nil }
        guard let resultMessage = appDelegate.guidanceMessage[guidanceKey] else { return nil }
        
        code.text = angleRecognition
        angle.text = codeRecognition
        
        let playbackSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")

        // 認識開始の効果音再生
        let openStartFile = "GeneralStart"
        let delayStartTime = fetchIntervalEffectSound(fileName: openStartFile)
        playMP3File(url: fetchMP3File(file: openStartFile))

        // 案内文再生
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStartTime / Double(playbackSpeed)) {
            print(delayStartTime,delayStartTime / Double(playbackSpeed))
            self.requests(url: mp3URL, completion: { streamURL in
                self.playMP3File(url: streamURL)
            })
        }
        
        // 認識終了の効果音再生
        let openFinishFile = "GeneralFinish"
        playEndEffectSound(url: mp3URL, completion: { playbackTime in
            DispatchQueue.main.asyncAfter(deadline: .now() + (delayStartTime + playbackTime) / Double(playbackSpeed)) {
                print("finish test start")
                if self.playingTheGuide != true { return }
                print("finish test end")
                self.playMP3File(url: self.fetchMP3File(file: openFinishFile))
                self.guidance.text = self.initGuidanceMessage
                self.playingTheGuide = false
            }
        })
        
 
        playingTheGuide = true
        // 案内文を更新
        if resultMessage.prefix(4) == "http" {
            guidance.text = appDelegate.callMessage[guidanceKey] ?? "未登録"
        } else {
            guidance.text = resultMessage
            return nil
        }

        guard let webURL = appDelegate.guidanceMessage[guidanceKey] else { return nil }
        return SFSafariViewController(url: NSURL(string: webURL)! as URL)
    }
    
    func fetchMP3File(file: String) -> URL {
        guard let startedPath = Bundle.main.path(forResource: file, ofType:"mp3") else {
            fatalError("Cannot find mp3 file: GuidanceTextHasStartedPlaying")
        }
        return URL(fileURLWithPath: startedPath)
    }
    
    func fetchIntervalEffectSound(fileName: String) -> Double {
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
    
    func playEndEffectSound(url: URL, completion: @escaping (_ playbackTaime: Double) -> Void) {
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
    
    func playStreamingMusic(url: URL) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            self.playMP3File(url: URL!)
        }
        downloadTask.resume()
    }
    
    func requests(url: URL, completion: @escaping (URL) -> Void) {
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            completion(URL!)
        }
        downloadTask.resume()
    }
}

extension ViewController: AVAudioPlayerDelegate {
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
        guard let webView = safariVC else { return }
        if openSafariVC { return }
        webView.delegate = self
        present(webView, animated: true, completion: nil)
    }
}

extension ViewController: SFSafariViewControllerDelegate {
    // 画面の読み込み完了時に呼び出し
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        openSafariVC = true
    }
    
    // Doneタップ時に呼び出し
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guidance.text = initGuidanceMessage
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.openSafariVC = false
        }
    }
}
