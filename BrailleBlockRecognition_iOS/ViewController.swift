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

    @IBAction func stop(_ sender: Any) {
        
        audioPlayer.stop()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if initCamera() {
            session.startRunning()
        }else{
            assert(false) //カメラが使えない
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
        let dialog = UIAlertController(title: "事前ダウンロード", message: "更新しますか？", preferredStyle: .alert)
        // 選択肢(ボタン)を2つ(OKとCancel)追加します
        //   titleには、選択肢として表示される文字列を指定します
        //   styleには、通常は「.default」、キャンセルなど操作を無効にするものは「.cancel」、削除など注意して選択すべきものは「.destructive」を指定します
        dialogCheck = false
        dialog.addAction(UIAlertAction(title: "更新", style: .default,
                                       handler:{ action in
                                        self.DLwait = Reader().httpGet()
        }))
        dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel,
                                       handler:{ action in
                                        self.dialogCheck = true
                                                }))
        // 生成したダイアログを実際に表示します
        self.present(dialog, animated: true, completion: nil)
        
    }
    
    // カメラの準備処理
    func initCamera() -> Bool {
        let preset = AVCaptureSession.Preset.medium //解像度
        //解像度
        //        AVCaptureSession.Preset.Photo : 852x640
        //        AVCaptureSession.Preset.High : 1280x720
        //        AVCaptureSession.Preset.Medium : 480x360
        //        AVCaptureSession.Preset.Low : 192x144


        let frame = CMTimeMake(value: 1, timescale: 20) //フレームレート
        let position = AVCaptureDevice.Position.back //フロントカメラかバックカメラか

        setImageViewLayout(preset: preset)//UIImageViewの大きさを調整

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
            if(self.DLwait){
                self.dialogCheck = true
            }
            if(self.dialogCheck){
                let img = self.captureImage(sampleBuffer) //UIImageへ変換
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
                resultCode = result[1] as! Int
                resultAngle = result[2] as! Int
                // *****************************************
                
                //15回の処理結果中の最頻値を採用
                if(bufCode.count < 30){
                    bufCode.append(resultCode)
                    bufAngle.append(resultAngle)
                    resultCode = self.userDefaults.integer(forKey: "code")
                    resultAngle = self.userDefaults.integer(forKey: "angle")
                }
                else{
                    resultCode = self.mode(bufCode)[0]
                    resultAngle = self.mode(bufAngle)[0]
                    //案内文取得
                    //Code=0の時、angle=-1に　同code、angleの場合でも読み込ますため
                    if(resultCode == 0){resultAngle = -1}
                        
                    else if(resultCode != self.userDefaults.integer(forKey: "code") ||
                        resultAngle != self.userDefaults.integer(forKey: "angle")){
                        //案内文取得
                        Reader().reader_IS(code: Int(resultCode),angle: Int(resultAngle))
                        //案内音声取得
                        let mp3 = String(format: "wm%05d_%d.mp3",resultCode,resultAngle)
                        if (Audio().existingFile(fileName: mp3) == false){
                            Audio().writeAudio(mp3: mp3)
                        }
                        
                        let data = Audio().readAudio(mp3: mp3)
                        do{
                            self.audioPlayer = try AVAudioPlayer(data:data as Data)
                            self.audioPlayer.play()
                        }catch{
                            print("再生エラー")
                        }
                    }
                    
                    self.userDefaults.set(resultCode, forKey: "code")
                    self.userDefaults.set(resultAngle, forKey: "angle")
                    
                    bufCode.removeAll()
                    bufAngle.removeAll()
                }
                
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

    //imageViewの大きさを調整
    func setImageViewLayout(preset: AVCaptureSession.Preset){
        let width = self.view.frame.width
        var height:CGFloat
        switch preset {
        case .photo:
            height = width * 852 / 640
        case .high:
            height = width * 1280 / 720
        case .medium:
            //height = width * 480 / 360
            height = width * 370 / 360
        case .low:
            height = width * 192 / 144
        case .cif352x288:
            height = width * 352 / 288
        case .hd1280x720:
            height = width * 1280 / 720
        default:
            height = self.view.frame.height
        }
        cameraImageView.frame = CGRect(x: 0, y: 50, width: width, height: height)
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
}
/*
extension ViewController: AVAudioPlayerDelegate {
    func playSound(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else {
            print("音源ファイルが見つかりません")
            return
        }
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self
            // 音声の再生
            audioPlayer.play()
        } catch {
        }
    }
}
*/
