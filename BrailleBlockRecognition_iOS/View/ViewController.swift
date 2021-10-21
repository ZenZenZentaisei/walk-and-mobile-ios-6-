import UIKit
import SafariServices

class ViewController: UIViewController {
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var code: UITextField!
    @IBOutlet weak var angle: UITextField!
    @IBOutlet weak var guidance: UITextView!
    
    var infoBarButtonItem: UIBarButtonItem!     // 編集ボタン
    
    let guideVoice = AudioPlayerModel()
    let codeBlock = CodeBlockController()
    let videoCapture = VideoCaptureModel()
    
    var safariVC: SFSafariViewController?
    
    var guideText = "認識中"
    
    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        guideText = guideVoice.stopMP3File()
    }
    //自動スリープを無効化
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      UIApplication.shared.isIdleTimerDisabled = true  // この行
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeBlock.fetchGuideInformation()
        
        videoCapture.startCapturing()
        videoCapture.delegate = self
        guideVoice.delegate = self
       
        infoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .done, target: self, action: #selector(infoBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = infoBarButtonItem
        guidance.text = guideText
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoCapture.stopCapturing()
    }
    
    @objc func infoBarButtonTapped(_ sender: UIBarButtonItem) {
        let infoVC = self.storyboard?.instantiateViewController(withIdentifier: "infoVC") as! InfoViewController
        infoVC.infoCodeData = codeBlock
        let nav = UINavigationController(rootViewController: infoVC)
        self.present(nav, animated: true, completion: nil)
    }
}

extension ViewController: VideoCaptureDelegate {
    func didCaptureFrame(display: UIImage, code: String, angle: String) {
        cameraImageView.image = display
        self.code.text = code
        self.angle.text = angle
        guidance.text = guideText
        
        let guidanceKey = code + angle
        let resultCall = codeBlock.resultValue(key: guidanceKey, type: .call) ?? "未登録"
        guard let resultMessage = codeBlock.resultValue(key: guidanceKey, type: .guidance) else { return }
        
        if guideVoice.process { return }
        guideVoice.process = true
        
        if let loadURL = codeBlock.resultValue(key: guidanceKey, type: .streaming)  {
            // online
            guard let mp3URL = URL(string: "http://18.224.144.136/tenji/" + loadURL) else { return }
            reflectImageProcessing(url: mp3URL, message: resultMessage, call: resultCall)
        } else {
            // offline
            reflectImageProcessing(message: resultMessage, call: resultCall)
        }
    }
    
    private func reflectImageProcessing(url: URL, message: String, call: String) {
        guideVoice.onlineReadGuide(mp3URL: url, completion: { initText in
            // 案内文を初期化
            self.guideText = initText
            
            if let web = NSURL(string: message) {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                self.safariVC = SFSafariViewController(url: web as URL, configuration: config)
            } else {
                self.guideVoice.process = false
            }
        })
        
        // 案内文を更新
        if message.prefix(4) == "http" {
            guideText = call
        } else {
            guideText = message
        }
    }
    
    private func reflectImageProcessing(message: String, call: String) {
        // 案内文を更新
        if message.prefix(4) == "http" {
            guideText = call
        } else {
            guideText = message
        }
        guideVoice.offlineReadGuide(manuscript: call)
    }
}

extension ViewController: AudioPlayerDelegate {
    // 音が鳴り終わったら呼び出される
    func didFinshPlaying() {
        guard let webView = safariVC else { return }
        webView.delegate = self
        present(webView, animated: false, completion: nil)
    }
    
    // 文字を読み終えたら呼び出される
    func didFinishReading() {
        guideVoice.process = false
        guideText = "認識中"
    }
}

extension ViewController: SFSafariViewControllerDelegate {
    // 画面の読み込み完了時に呼び出される
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        safariVC = nil
    }
    
    // 画面が閉じる時に呼び出される
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        videoCapture.startCapturing()
        guideVoice.process = false
    }
}
