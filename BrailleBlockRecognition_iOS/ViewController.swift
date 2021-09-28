//
//  ViewController.swift

//import Network
import UIKit
import AVFoundation
import CoreData
import Network

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate,AVAudioPlayerDelegate {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var codetext: UILabel!
    
  

    var audioPlayer = AVAudioPlayer()
    
    var reproduction = false
    
    
    var openCV = OpenCV()

    var session: AVCaptureSession! //セッション
    var device: AVCaptureDevice! //カメラ
    var output: AVCaptureVideoDataOutput! //出力先
    
    weak var ManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    var configBool = false
    var GuideVoice = true
    var stop_bool = false
    var dialogCheck = false
    var DLwait = false
    var networkBool = false
    //ネットワーク通信確認用
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    //本体設定の言語(t:日本語、f:英語)
    var langBool = true

    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        audioPlayer.stop()
        stop_bool = true
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
        
        //ネットワーク確認
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.networkBool = true
            } else {
                self.networkBool = false
            }
        }
        monitor.start(queue: queue)
        
        //本体設定の言語確認
        //[0]は、使用言語の優先順序1位(主言語)
        if(Locale.preferredLanguages[0] != "ja-JP"){
            langBool = false
        } else {
            langBool = true
        }
    }
    
    //値の送受信(設定画面)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   
        
        let next = segue.destination as? Config
        //値を送信
        next?.configBool = configBool
        //値を受信
        next?.resultHandler = { setting in
            self.configBool = setting
            //設定の保存
//            self.userDefaults.set(self.configBool, forKey: "configBool")
        //}
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.userDefaults.set("案内文はここに表示されます", forKey: "IS")
        
        if(networkBool){

            // 選択肢(ボタン)を2つ(OKとCancel)追加します
            //   titleには、選択肢として表示される文字列を指定します
            //   styleには、通常は「.default」、キャンセルなど操作を無効にするものは「.cancel」、削除など注意して選択すべきものは「.destructive」を指定します
            dialogCheck = false
        }
        else{
            self.dialogCheck = true
        }
    }
    
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
            var result: NSArray
            var bufCode: [Int]  = []
            var bufAngle: [Int]  = []

            var resultImg: UIImage
            var resultCode: Int
            var resultAngle: Int
                
            // *************** 画像処理 ***************
            result = self.openCV.reader(img)! as NSArray
                
            //変換
            resultImg = result[0] as! UIImage
            resultCode = result[1] as! Int
            resultAngle = result[2] as! Int
    
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
                //案内音声取得
                if(resultCode != 0){
                    if(self.stop_bool == false){
                        //保存先ディレクトリの分岐
                        let mp3:String
                        if(self.langBool){
                            mp3 = String(format: "message/wm%05d_%d.mp3",resultCode,resultAngle)
                        } else {
                            mp3 = String(format: "message_en/wm%05d_%d.mp3",resultCode,resultAngle)
                        }
                            
                        if (Audio().existingFile(mp3: mp3) == false || (self.configBool == true)) {
                            Audio().writeAudio(mp3: mp3)
                        }
                        let data = Audio().readAudio(mp3: mp3)
                        do{
                            self.audioPlayer = try AVAudioPlayer(data:data as Data)
                            self.audioPlayer.play()
                        } catch {
                            print("再生エラー")
                        }
                    }
                }
                bufCode.removeAll()
                bufAngle.removeAll()
            }

            self.cameraImageView.image = resultImg
            if self.reproduction {
                return
            } else {
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                self.code.text = String(resultCode)
                self.angle.text = String(resultAngle)
                self.codetext.text = appDelegate.localDB[String(resultCode) + String(resultAngle)] ?? "認識中"
                if let mp3URL = appDelegate.mp3[String(resultCode) + String(resultAngle)] {
                    let urlstring = "http://18.224.144.136/tenji/" + mp3URL
                    let url = NSURL(string: urlstring)
                    print("the url = \(url!)")
                    self.downloadFileFromURL(url: url! as URL)
                    self.reproduction = true
                }
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finish!")
        reproduction = false
        code.text = "認識中"
    }
    
    func downloadFileFromURL(url:URL){
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url as URL) { (URL, response, error) in
            self.play(url: URL!)
        }
        downloadTask.resume()
    }
    func play(url:URL) {
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0
            audioPlayer.delegate = self
            audioPlayer.play()
        } catch let error as NSError {
            //self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }

    // sampleBufferからUIImageを作成
    func captureImage(_ sampleBuffer:CMSampleBuffer) -> UIImage{
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

        if alert != nil {
//            alert?.message = now + "/" + max + "件"
//            if(now != "0" && now == max ){
//                alert!.dismiss(animated: false, completion: nil)
//            }
        }
        else{
            alert = UIAlertController(title: "コードデータ取得中", message: "now loading...", preferredStyle: .alert)
            self.present(alert!, animated: true, completion: nil)
//            self.userDefaults.set(0, forKey: "nowdata")
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
