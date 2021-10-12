import UIKit
import AVFoundation
import SafariServices

class ViewController: UIViewController {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var guidance: UITextView!
    
    var infoBarButtonItem: UIBarButtonItem!     // 編集ボタン
  
    var audioPlayer = AVAudioPlayer()
    
    var reproduction = false
    var safariVC: SFSafariViewController?
    
    let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    var openCV = OpenCV()

    var session: AVCaptureSession! //セッション
    var device: AVCaptureDevice! //カメラ
    var output: AVCaptureVideoDataOutput! //出力先
    

    var configBool = false
    var stop_bool = false


    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        audioPlayer.stop()
        reproduction = false
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

        //URLジャンプから戻ってきたことを検知
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
       
        infoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .done, target: self, action: #selector(infoBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = infoBarButtonItem
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    //最頻値の算出
    func mode(_ array:[Int])->[Int]{
        var sameList:[Int]=[]
        var countList:[Int]=[]
        for item in array{
            if let index=sameList.firstIndex(of: item){
                countList[index] += 1
            }else{
                sameList.append(item)
                countList.append(1)
            }
        }
        let maxCount=countList.max(by: {$1 > $0})
        var modeList:[Int]=[]
        for index in 0..<countList.count{
            if countList[index]==maxCount!{
                modeList.append(sameList[index])
            }
        }
        return modeList
    }
    //進捗表示
    func progress(){
        var tc = UIApplication.shared.keyWindow?.rootViewController;
        while ((tc!.presentedViewController) != nil) {
            tc = tc!.presentedViewController;
        }
        var alert = tc as? UIAlertController

        if alert == nil {
            alert = UIAlertController(title: "コードデータ取得中", message: "now loading...", preferredStyle: .alert)
            self.present(alert!, animated: true, completion: nil)
        }
    }
    //opencv内初期化(応急処置)　したくない
    func codeZero(){
        let Image = UIImage(named: "sample")!
        _ = self.openCV.reader(Image)
        print("zero")
    }
    
    @objc func applicationWillEnterForeground() {
        codeZero()
    }

}
//一応残しておく
extension UIImage {
    // resize image
    func reSizeImage(reSize:CGSize)->UIImage {
            //UIGraphicsBeginImageContext(reSize);
            UIGraphicsBeginImageContextWithOptions(reSize,false,UIScreen.main.scale);
            self.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height));
            let reSizeImage:UIImage! = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return reSizeImage;
        }

    // scale the image at rates
    func scaleImage(scaleSize:CGFloat)->UIImage {
        let reSize = CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return reSizeImage(reSize: reSize)
    }
    
    func cropping(to: CGRect) -> UIImage? {
            var opaque = false
            if let cgImage = cgImage {
                switch cgImage.alphaInfo {
                case .noneSkipLast, .noneSkipFirst:
                    opaque = true
                default:
                    break
                }
            }

            UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
            draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
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
        DispatchQueue.main.async{ //非同期処理として実行
            var img = self.captureImage(sampleBuffer) //UIImageへ変換
            //画像拡大処理(中心から小さく切り抜く)
            let rectX = img.size.width * 0.5
            let rectY = img.size.height * 0.5

            img = img.cropping(to: CGRect(x: (img.size.width - rectX)/2, y: (img.size.height - rectY)/2, width: rectX, height: rectY))!

            //結果を格納する
            var bufCode: [Int]  = []
            var bufAngle: [Int]  = []
                
            // *************** 画像処理 ***************
            let result = self.openCV.reader(img)! as NSArray
                
            //変換
            let resultImg = result[0] as! UIImage
            var resultCode = result[1] as! Int
            var resultAngle = result[2] as! Int
    
            // ****************************************
                
            //音声再生中は動作させない
            if(self.audioPlayer.isPlaying){
                if(resultCode != 0){
                    self.codeZero()
                }
            }
            //10回の処理結果中の最頻値を採用
            else if(bufCode.count < 10){
                bufCode.append(resultCode)
                bufAngle.append(resultAngle)
            } else {
                resultCode = self.mode(bufCode)[0]
                resultAngle = self.mode(bufAngle)[0]
                //案内文取得
                //Code=0の時、angle=-1に　同code、angleの場合でも読み込ますため
                if(resultCode == 0){
                    resultAngle = -1
                }
//                //案内音声取得
//                if(resultCode != 0){
//                    if(self.stop_bool == false){
//                        //保存先ディレクトリの分岐
//                        let mp3:String
////                        if(self.langBool){
////                            mp3 = String(format: "message/wm%05d_%d.mp3",resultCode,resultAngle)
////                        } else {
////                            mp3 = String(format: "message_en/wm%05d_%d.mp3",resultCode,resultAngle)
////                        }
//
//                        if (Audio().existingFile(mp3: mp3) == false || (self.configBool == true)) {
//                            Audio().writeAudio(mp3: mp3)
//                        }
//                        let data = Audio().readAudio(mp3: mp3)
//                        do{
//                            self.audioPlayer = try AVAudioPlayer(data:data as Data)
//                            self.audioPlayer.play()
//                        } catch {
//                            print("再生エラー")
//                        }
//                    }
//                }
                bufCode.removeAll()
                bufAngle.removeAll()
            }

            self.cameraImageView.image = resultImg
            
            if self.reproduction { return }
            self.safariVC = self.reflectRecognition(angleRecognition: "\(resultCode)", codeRecognition: "\(resultAngle)")
        }
    }
    
    // 認識結果を画面に反映
    func reflectRecognition(angleRecognition: String, codeRecognition: String) -> SFSafariViewController? {
        let guidanceKey = angleRecognition + codeRecognition
        self.code.text = angleRecognition
        self.angle.text = codeRecognition
        
        if let mp3URL = appDelegate.voice[guidanceKey] {
            let urlstring = "http://18.224.144.136/tenji/" + mp3URL
            let url = NSURL(string: urlstring)
            print("the url = \(url!)")
            self.downloadFileFromURL(url: url! as URL)
            self.reproduction = true
        }
        
        if let resultMessage = appDelegate.guidanceMessage[guidanceKey] {
            if resultMessage.prefix(4) == "http" {
                self.guidance.text = appDelegate.callMessage[guidanceKey] ?? "未登録"
            } else {
                self.guidance.text = resultMessage
                return nil
            }
        } else {
            self.guidance.text = "確認中"
        }

        guard let webURL = appDelegate.guidanceMessage[guidanceKey] else { return nil }
        return SFSafariViewController(url: NSURL(string: webURL)! as URL)
    }
    
    func downloadFileFromURL(url:URL){
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            self.play(url: URL!)
        }
        downloadTask.resume()
    }
    
}

extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let webView = safariVC {
            webView.delegate = self
            self.present(webView, animated: true, completion: nil)
        } else {
            reproduction = false
            guidance.text = "認識中"
        }
    }
    
    
    func play(url:URL) {
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            audioPlayer.enableRate = true
            print(UserDefaults.standard.float(forKey: "reproductionSpeed"))
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
}

extension ViewController: SFSafariViewControllerDelegate {
    // 画面の読み込み完了時に呼び出し
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        self.reproduction = true
    }
    // Doneタップ時に呼び出し
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guidance.text = "認識中"
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(3)
            self.reproduction = false
        }
    }
}
