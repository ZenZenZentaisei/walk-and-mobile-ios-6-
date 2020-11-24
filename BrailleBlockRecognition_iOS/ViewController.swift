//
//  ViewController.swift


import UIKit
import AVFoundation
import CoreData

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var codetext: UILabel!
    
    
    var openCV = OpenCV()

    var session: AVCaptureSession! //セッション
    var device: AVCaptureDevice! //カメラ
    var output: AVCaptureVideoDataOutput! //出力先
    
    var userDefaults = UserDefaults.standard
    
    var dialogCheck = false
    var DLwait = false
    
    var ManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var audioPlayer = AVAudioPlayer()
    
    var config_bool = false
    var GuideVoice = true
    var stop_bool = false

    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        audioPlayer.stop()
        stop_bool = true
        
    }
    //自動スリープを無効化
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      UIApplication.shared.isIdleTimerDisabled = true  // この行
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if initCamera() {
            session.startRunning()
        }else{
            assert(false) //カメラが使えない
        }
        config_bool = userDefaults.bool(forKey: "config_bool")
        
        //URLジャンプから戻ってきたことを検知
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    //値の送受信(設定画面)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //segueの指定は省く(今回は1対1なので)
        
       // if segue.identifier == "2" {
        
        let next = segue.destination as? Config
        //値を送信
        next?.config_bool = config_bool
        //値を受信
        next?.resultHandler = { setting in
            self.config_bool = setting
            //設定の保存
            self.userDefaults.set(self.config_bool, forKey: "config_bool")
        //}
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.userDefaults.set("案内文はここに表示されます", forKey: "IS")
        
        // ダイアログ(AlertControllerのインスタンス)を生成します
        //   titleには、ダイアログの表題として表示される文字列を指定します
        //   messageには、ダイアログの説明として表示される文字列を指定します
        let dialog = UIAlertController(title: "事前ダウンロード",
                                       message: "案内文章と案内音声をダウンロードしますか？ダウンロードしておくことでオフライン時でも使用できるようになります。案内音声は容量が大きいためWi-Fi環境でのダウンロードが推奨されます。(約12MB)",
                                       preferredStyle: .alert)
        // 選択肢(ボタン)を2つ(OKとCancel)追加します
        //   titleには、選択肢として表示される文字列を指定します
        //   styleには、通常は「.default」、キャンセルなど操作を無効にするものは「.cancel」、削除など注意して選択すべきものは「.destructive」を指定します
        dialogCheck = false
        dialog.addAction(UIAlertAction(title: "両方取得", style: .default,
                                       handler:{ action in
                                        self.GuideVoice = true
                                        self.DLwait = true
                                        self.userDefaults.set(self.DLwait, forKey: "dlwait")
                                        Reader().httpGet(GuideVoice: self.GuideVoice)
                                        self.dialogCheck = true
        }))
        dialog.addAction(UIAlertAction(title: "案内文章のみ取得", style: .default,
                                       handler:{ action in
                                        self.GuideVoice = false
                                        self.DLwait = true
                                        self.userDefaults.set(self.DLwait, forKey: "dlwait")
                                        Reader().httpGet(GuideVoice: self.GuideVoice)
                                        self.dialogCheck = true
        }))
        dialog.addAction(UIAlertAction(title: "キャンセル", style: .cancel,
                                       handler:{ action in
                                        self.dialogCheck = true
                                                }))
        // 生成したダイアログを実際に表示します
        self.present(dialog, animated: true, completion: nil)
        
    }
    
    // カメラの準備処理
    func initCamera() -> Bool {
        let preset = AVCaptureSession.Preset.photo //解像度
        //解像度
        //        AVCaptureSession.Preset.Photo : 852x640
        //        AVCaptureSession.Preset.High : 1280x720
        //        AVCaptureSession.Preset.Medium : 480x360
        //        AVCaptureSession.Preset.Low : 192x144


        let frame = CMTimeMake(value: 1, timescale: 20) //フレームレート
        let position = AVCaptureDevice.Position.back //フロントカメラかバックカメラか

        //setImageViewLayout(preset: preset)//UIImageViewの大きさを調整

        // セッションの作成.
        session = AVCaptureSession()

        // 解像度の指定.
        session.sessionPreset = preset

        // デバイス取得.
        device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                           for: AVMediaType.video,
                                           position: position)

        // VideoInputを取得.
        var input: AVCaptureDeviceInput! = nil
        do {
            input = try
            AVCaptureDeviceInput(device: device) as AVCaptureDeviceInput
        } catch let error {
            print(error)
            return false
        }

        // セッションに追加.
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            return false
        }

        // 出力先を設定
        output = AVCaptureVideoDataOutput()

        //ピクセルフォーマットを設定
        output.videoSettings =
            [ kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA) ]

        //サブスレッド用のシリアルキューを用意
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        // 遅れてきたフレームは無視する
        output.alwaysDiscardsLateVideoFrames = true

        // FPSを設定
        do {
            try device.lockForConfiguration()

            device.activeVideoMinFrameDuration = frame //フレームレート
            device.unlockForConfiguration()
        } catch {
            return false
        }

        // セッションに追加.
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            return false
        }

        // カメラの向きを合わせる
        for connection in output.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }

        return true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async{ //非同期処理として実行
            if(self.dialogCheck && self.DLwait){
                
                if(self.GuideVoice == true){self.progress()}
                
                self.DLwait = self.userDefaults.bool(forKey: "dlwait")
                
            }
            else if(self.dialogCheck && self.DLwait == false){
                
                var img = self.captureImage(sampleBuffer) //UIImageへ変換
                
                //画像拡大処理(中心から小さく切り抜く)
                let rectX = img.size.width * 0.9
                let rectY = img.size.height * 0.9
                img = img.cropping(to: CGRect(x: (img.size.width - rectX)/2, y: (img.size.height - rectY)/2, width: rectX, height: rectY))!
                
                //print("---img---")
                //print(img.size.width)
                //print(img.size.height)
                
                //結果を格納する
                var result: NSArray
                var bufCode: [Int]
                var bufAngle: [Int]
                if let _ = UserDefaults.standard.array(forKey: "codes"){
                    bufCode = self.userDefaults.array(forKey: "codes") as! [Int]
                }
                else{
                    bufCode = []
                }
                if let _ = UserDefaults.standard.array(forKey: "angles"){
                    bufAngle = self.userDefaults.array(forKey: "angles") as! [Int]
                }
                else{
                    bufAngle = []
                }
                
                var resultImg: UIImage
                var resultCode: Int
                var resultAngle: Int
                
                // *************** 画像処理 ***************
                result = self.openCV.reader(img)! as NSArray
                
                //変換
                resultImg = result[0] as! UIImage
                
                //print("---Rimg---")
                //print(resultImg.size.width)
                //print(resultImg.size.height)
                
                resultCode = result[1] as! Int
                resultAngle = result[2] as! Int
    
                // ****************************************
                
                //音声再生中は動作させない
                if(self.audioPlayer.isPlaying){}
                //10回の処理結果中の最頻値を採用
                else if(bufCode.count < 10){
                    bufCode.append(resultCode)
                    bufAngle.append(resultAngle)
                }
                else{
                    resultCode = self.mode(bufCode)[0]
                    resultAngle = self.mode(bufAngle)[0]
                    //案内文取得
                    //Code=0の時、angle=-1に　同code、angleの場合でも読み込ますため
                    if(resultCode == 0){
                        resultAngle = -1
                    }
                    else if(resultCode != self.userDefaults.integer(forKey: "code") ||
                        resultAngle != self.userDefaults.integer(forKey: "angle")){
                        //案内文取得
                        Reader().reader_IS(code: Int(resultCode),angle: Int(resultAngle))
                        
                        self.stop_bool = false
                    }
                    
                    //案内音声取得
                    if(resultCode != 0){
                        if(self.stop_bool == false){
                            let mp3 = String(format: "wm%05d_%d.mp3",resultCode,resultAngle)
                            if (Audio().existingFile(fileName: mp3) == false ||
                                        (self.config_bool == true)){
                                Audio().writeAudio(mp3: mp3)
                            }
                            let data = Audio().readAudio(mp3: mp3)
                            do{
                                self.audioPlayer = try AVAudioPlayer(data:data as Data)
                                self.audioPlayer.play()
                                
                                //カメライメージ初期化
                                self.code_zero()
                                
                            }catch{
                                print("再生エラー")
                            }
                        }
                        //案内文にURLが含まれていれば、ブラウザにジャンプ
                        if(self.userDefaults.string(forKey: "IS")?.prefix(4) == "http"){
                            
                            sleep(1)
                            while(self.audioPlayer.isPlaying){}
                            
                            var IS = self.userDefaults.string(forKey: "IS")! as String
                            //改行が入っているので、排除
                            IS = IS.trimmingCharacters(in: .newlines)

                            //日本語を含むURLにも対応させるため、パーセントエンコーディング
                            let encodeUrlString: String = IS.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                            
                            //連続して、ジャンプさせないために初期化
                            //他の初期化はapplicationWillEnterForeground()に
                            resultCode = 0
                            bufCode.removeAll()
                            bufAngle.removeAll()
                            
                            //URLの設定
                            let url = URL(string: encodeUrlString)
                            if(UIApplication.shared.canOpenURL(url!) ) {
                                UIApplication.shared.open(url!)
                            }
                            
                        }
                    }
                    
                    self.userDefaults.set(resultCode, forKey: "code")
                    self.userDefaults.set(resultAngle, forKey: "angle")
                    
                    bufCode.removeAll()
                    bufAngle.removeAll()
                }
                
                resultCode = self.userDefaults.integer(forKey: "code")
                resultAngle = self.userDefaults.integer(forKey: "angle")
                
                self.userDefaults.set(bufCode, forKey: "codes")
                self.userDefaults.set(bufAngle, forKey: "angles")
                // 表示
                self.cameraImageView.image = resultImg
                self.code.text = String(resultCode)
                self.angle.text = String(resultAngle)
                self.codetext.text = self.userDefaults.string(forKey: "IS")
                
            }
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
        let max = String(self.userDefaults.integer(forKey: "maxdata"))
        let now = String(self.userDefaults.integer(forKey: "nowdata"))
        
        if alert != nil {
            alert?.message = now + "/" + max + "件"
            if(now != "0" && now == max ){
                alert!.dismiss(animated: false, completion: nil)
            }
        }
        else{
            alert = UIAlertController(title: "コードデータ取得中", message: "now loading...", preferredStyle: .alert)
            self.present(alert!, animated: true, completion: nil)
            self.userDefaults.set(0, forKey: "nowdata")
        }
    }
    //opencv内初期化(応急処置)　したくない
    func code_zero(){
        
        self.userDefaults.set(0, forKey: "code")
        self.userDefaults.set(-1, forKey: "angle")
        self.userDefaults.set([], forKey: "codes")
        self.userDefaults.set([], forKey: "angles")
        let Image = UIImage(named: "sample")!
        _ = self.openCV.reader(Image)
    }
    
    @objc func applicationWillEnterForeground() {
        code_zero()
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
