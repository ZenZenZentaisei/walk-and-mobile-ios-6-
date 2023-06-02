import UIKit
import SafariServices
import CoreLocation
import CoreMotion
import AVFoundation//変更箇所

class ViewController: UIViewController, UIGestureRecognizerDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var genres: UIButton!
    @IBOutlet weak var guidance: UITextView!
    
    // 編集ボタン
    var infoBarButtonItem: UIBarButtonItem!
    
    let guideVoice = AudioPlayerModel()
    let codeBlock = CodeBlockController()
    let videoCapture = VideoCaptureModel()
    let captureSession = AVCaptureSession()//変更箇所
    let locationManager = CLLocationManager()
    
    var safariVC: SFSafariViewController?//Safariアプリに飛ばす
    var coupons: [[String: Any]] = []
    var guideText = NSLocalizedString("Verification", comment: "")
    var guideTextClone = NSLocalizedString("Verification", comment: "")
    var voiceGuidance = String()
    var urlMessage = String()
    var tapCount : Int = 0
    var genre = String()
    var genreName = NSLocalizedString("normal", comment: "")
    var fontsize = NSLocalizedString("Medium", comment: "")
    var ecomode = UserDefaults.standard.string(forKey: "ecomode") ?? "nil"
    var Latitude: String = ""///
    var Longitude: String = ""///
    
    //加速度センサで利用する変数
    let motionManager = CMMotionManager()
    var acceleX: Double = 0.0
    var acceleY: Double = 0.0
    var acceleZ: Double = 0.0
    let Alpha = 0.4
    var flg: Bool = false
    
    //ジャンル(messagecategory)選択ボタン及び切り替え
    /* ジャンル(messgecategory)対応表
        一般(normal) : "0"
        詳細(detail) : "1"
        避難(evacuation) : "2"
        専用(exclusive) : "3"
     */
    @IBAction func genres(_ sender: UIButton) {
        if tapCount == 0{
            sender.setTitle(NSLocalizedString("normal", comment: ""), for: .normal)
            genre = "0"
            tapCount += 1
        }
        else if tapCount == 1{
            sender.setTitle(NSLocalizedString("detail", comment: ""), for: .normal)
            genre = "1"
            tapCount += 1
        }
        else if tapCount == 2{
            sender.setTitle(NSLocalizedString("evacuation", comment: ""), for: .normal)
            genre = "2"
            tapCount += 1
        }
        else if tapCount == 3{
            sender.setTitle(NSLocalizedString("exclusive", comment: ""), for: .normal)
            genre = "3"
            tapCount = 0
        }
        genreName = genres.currentTitle ?? "error"
    }
    
    func stopmotion() {
        guideVoice.stop()
        guideText = ""
        urlMessage = ""
        code.text = "\(0)"
        angle.text = "\(0)"
        genres.setTitle(NSLocalizedString(genreName, comment: ""), for: .normal)
        cameraImageView.layer.borderColor = UIColor.clear.cgColor
        
    }
    
    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        stopmotion()
    }
    @IBAction func pause(_ sender: Any) {
        changeColorFrame()
        guideVoice.pause()
        
    }
    @IBAction func resume(_ sender: Any) {
        changeColorFrame()
        guideVoice.playback()
    }
    //リピートボタン
    @IBAction func echo(_ sender: Any) {
        changeColorFrame()
        guideText = guideTextClone
        guideVoice.echo(manuscript: voiceGuidance, lang: codeBlock.language!)
        print(voiceGuidance)
        if voiceGuidance != ""{
            videoCapture.stopCapturing()
        }
    }
    //自動スリープを無効化
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidLoad() {//Viewが読みこれまれた時の処理
        super.viewDidLoad()//ライフサイクルメソッドによる記述。決まりのようなもの。下からの処理の解析を行うことに意味がある。
        //サーバーからデータ取得
        codeBlock.fetchGuideInformation()
        //省電力モードによるカメラの起動の処理
        videoCapture.startCapturing()
        if ecomode == "ON"{
            videoCapture.stopCapturing()
        }
        videoCapture.delegate = self//全てのselfはViewControllerを示している？
        guideVoice.delegate = self
        
        //InfoVC(設定画面)へのボタン設置
        infoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .done, target: self, action: #selector(infoBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = infoBarButtonItem
        //ダブルタップ設定
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        //ダブルタップイベントを登録
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(
                        target: self,
                        action: #selector(tapped(_:)))
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 2//ダブルタップで反応
        self.view.addGestureRecognizer(tapGesture)
        //長押しイベントを登録
        let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPress(_:)))
        
        longpressGesture.delegate = self
        self.view.addGestureRecognizer(longpressGesture)
        guidance.text = guideText
        setDefaultButtonName()
    }
    //避難所情報取得機能で使う関数　↓
    @objc func tapped(_ sender: UITapGestureRecognizer){
        //ダブルタップした時の処理
        if genre == "2" {
            locationManager.requestLocation()   //現在地取得のやつ
            let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "toEvaVC") as! EvacuationViewController
            self.present(nextViewController, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let loc = locations.last else { return }
            
            CLGeocoder().reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
                
                if let error = error {
                    print("reverseGeocodeLocation Failed: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?[0] {
                    let Latitude = loc.coordinate.latitude
                    let Longitude = loc.coordinate.longitude
                    //print(Latitude, Longitude)
                    UserDefaults.standard.set(Latitude, forKey: "str0")
                    UserDefaults.standard.set(Longitude, forKey: "str1")
                }
            })
    }
        
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
    //周辺の避難所情報取得機能　↑
    
    //長押しした時の処理

    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        ecomode = UserDefaults.standard.string(forKey: "ecomode") ?? "nil"
        if ecomode == "ON"{
            if sender.state == .began{
                print("長押し開始")
                //カメラ開始(同じインスタンスを使い回すために、他とは書き方が異なる)
                videoCapture.captureSession.startRunning()
            }
            else if sender.state == .ended{
                print("長押し終了")
                //カメラ停止
                videoCapture.stopCapturing()
            }
        }
    }
    //文字の大きさ設定
    func setFontsize() {
        fontsize = UserDefaults.standard.string(forKey: "fontsize") ?? "nil"
        print(fontsize)
        if fontsize == "Small"{
            guidance.font = UIFont.systemFont(ofSize: 15)
        }
        else if fontsize == "Large"{
            guidance.font = UIFont.systemFont(ofSize: 25)
        }
        else{
            guidance.font = UIFont.systemFont(ofSize: 20)
        }
    }
    
    //一応ローパスフィルターを入れた（シェイク）
    func lowpassFilter(acceleration: CMAcceleration){
        acceleX = Alpha * acceleration.x + acceleX * (1.0 - Alpha);
        acceleY = Alpha * acceleration.y + acceleY * (1.0 - Alpha);
        acceleZ = Alpha * acceleration.z + acceleZ * (1.0 - Alpha);
        //加速度の絶対値が1.3を超えた時の処理（音声停止）
        if acceleX > 1.3 || acceleY > 1.3 || acceleZ > 1.3 || acceleX < -1.3 || acceleY < -1.3 || acceleZ < -1.3 {
            stopmotion()
        }
    }
    
    //加速度の測定を停止する
    func stopAccelerometer(){
        if (motionManager.isAccelerometerActive) {
            motionManager.stopAccelerometerUpdates()
        }
    }
    // ボタンの初期設定
    func setDefaultButtonName(){
        genres.setTitle(NSLocalizedString("normal", comment: ""), for: .normal)
        genre = "0"
        tapCount += 1
    }
    //ジャンルにデータが無い場合、ボタンを自動切り替え
    func setSwitchButtonName(){
        genres.setTitle(NSLocalizedString("normal", comment: ""), for: .normal)
        genre = "0"
    }
    
    // 認識中　赤枠線表示
    func changeColorFrame(){
        cameraImageView.layer.borderColor = UIColor.red.cgColor
        cameraImageView.layer.borderWidth = 5
    }
    //画面から移動した時に呼ばれる
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoCapture.stopCapturing()
    }
    //infoVCへのボタンを押した時の画面遷移設定とデリゲートを登録
    @objc func infoBarButtonTapped(_ sender: UIBarButtonItem) {
        let infoVC = self.storyboard?.instantiateViewController(withIdentifier: "infoVC") as! InfoViewController
        infoVC.infoCodeData = codeBlock
        infoVC.delegate = self
        let nav = UINavigationController(rootViewController: infoVC)
        self.present(nav, animated: true, completion: nil)
    }
}

extension ViewController: VideoCaptureDelegate {
    func didCaptureFrame(display: UIImage, code: String, angle: String) {
        // 画像表示
        cameraImageView.image = display
        // 案内文表示
        guidance.text = guideText
        // ある点字ブロックのキー作成
        let guidanceKey = code + angle + genre
        // 引数がSting型のためint型に変換
        let code = Int(code) ?? 0
        let angle = Int(angle) ?? -1
        // このifないと効果音だけが鳴り響く
        /* ifのパターン
         パターン　　　　　　　　　　　　　　　　｜　コード＆アングルの値 |
         カメラ常時起動(認識待ち)　　　　　　　 ｜　0　 　　  -1      |
         点字ブロックを認識したが、未登録だった　｜　1〜　　　  0〜     |　nil＝未登録として処理
         点字ブロックを認識し、登録があった　　　｜　1〜　　　  0〜     |
        */
        if code > 0 && angle > -1{
            changeColorFrame()
            // 読み方を取得
            let resultCalls = codeBlock.resultValue(key: guidanceKey, type: .call)
            let resultCall = resultCalls.1 ?? NSLocalizedString("Unregistered", comment: "")
            
            // 案内文を取得
            let resultMessages = codeBlock.resultValue(key: guidanceKey, type: .guidance)
            let key = resultMessages.0
            
            // データベースのキーと取得したキーを照合し、違ったら、ジャンルボタンを一般に変更
            if guidanceKey != key {
                setSwitchButtonName()
            }
            
            let resultMessage = resultMessages.1 ?? NSLocalizedString("Unregistered", comment: "")
            if guideVoice.process { return }
            guideVoice.process = true
        
            // 案内文にURLが入っている場合、読み方を表示し、読み方をアナウンスする
            if resultMessage.prefix(4) == "http"{
                guideText = resultCall
                voiceGuidance = resultCall
                urlMessage = resultMessage
            }
            //　読み方が無い場合、案内文を表示し、案内文をアナウンスする
            else if resultCall == "" {
                guideText = resultMessage
                voiceGuidance = resultMessage
            }
            /*else if resultCall == NSLocalizedString("Unregistered", comment: "") || resultCall == ""{
                guideText = resultMessage
                voiceGuidance = resultMessage
            }*/
            //通常(案内文も読み方もある場合、案内文を表示し、読み方をアナウンスする)
            else{
                guideText = resultMessage
                voiceGuidance = resultCall
            }
            
            guideTextClone = guideText
            guideVoice.readGuide(manuscript: voiceGuidance, genre: genre, lang: codeBlock.language!)
            if urlMessage != ""{
                guard let web = NSURL(string: urlMessage) else { return }
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                self.safariVC = SFSafariViewController(url: web as URL, configuration: config)
            }
            self.code.text = "\(code)"
            self.angle.text = "\(angle)"
        }
    }
}

extension ViewController: AudioPlayerDelegate {
    // 読み取り音が鳴り終わったら呼び出される
    func didFinishPlaying() {
        //シェイクの設定↓
        if motionManager.isAccelerometerAvailable {
            // intervalの設定 [sec]
            motionManager.accelerometerUpdateInterval = 0.2
            // センサー値の取得開始
            motionManager.startAccelerometerUpdates(
                to: OperationQueue.current!,
                withHandler: {(accelData: CMAccelerometerData?, errorOC: Error?) in
                    self.lowpassFilter(acceleration: accelData!.acceleration)
            })
        }
        videoCapture.stopCapturing()
        guard let webView = safariVC else { return }
        webView.delegate = self
        present(webView,animated: false,completion: nil)
    }
    
    // 文字を読み終えたら呼び出される
    func didFinishReading() {
        //省電力モードの処理
        if ecomode == "OFF"{
            videoCapture.startCapturing()
        }
        //加速度センサの読み取り停止
        self.stopAccelerometer()
        
        guideVoice.process = false
        //現在のジャンルに設定
        genres.setTitle(NSLocalizedString(genreName, comment: ""), for: .normal)
        //カメラ画面の枠色をクリア
        cameraImageView.layer.borderColor = UIColor.clear.cgColor
        //videoCapture.startCapturing()
        
        //URLの処理
        if urlMessage != ""{
            videoCapture.stopCapturing()
            guard let webView = safariVC else { return }
            webView.delegate = self
            present(webView, animated: false, completion: nil)
            urlMessage = ""
        }
    }
}

extension ViewController: SFSafariViewControllerDelegate {
    // 画面の読み込み完了時に呼び出される
    //アクションボタンタップ時
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        safariVC = nil
    }
    
    // 画面が閉じる時に呼び出される
    //完了ボタンタップ時
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if ecomode == "OFF"{
            videoCapture.startCapturing()
        }
        //videoCapture.startCapturing()
        guideVoice.process = false
        urlMessage = ""
        print("完了する")
    }
}

extension ViewController: InfoViewDelegate{
    //infoVCで完了ボタン押し時に呼ばれる
    func swtichCamera(ecomode: String) {
        videoCapture.captureSession.startRunning()
        if ecomode == "ON"{
            videoCapture.stopCapturing()
        }
    }
    
}
