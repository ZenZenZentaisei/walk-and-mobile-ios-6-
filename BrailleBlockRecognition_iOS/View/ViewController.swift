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
    
    var guideText = NSLocalizedString("Verification", comment: "")
    
    //音声停止ボタン 現在の再生、同code、angleでの連続再生を停止させる。
    @IBAction func stop(_ sender: Any) {
        guideText = guideVoice.stopMP3File()
        code.text = "\(0)"
        angle.text = "\(0)"
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
        guidance.text = guideText
        
        let guidanceKey = code + angle
        let resultCall = codeBlock.resultValue(key: guidanceKey, type: .call) ?? NSLocalizedString("Unregistered", comment: "")
        guard let resultMessage = codeBlock.resultValue(key: guidanceKey, type: .guidance) else { return }
        
        if guideVoice.process { return }
        guideVoice.process = true
        
        // 案内文を更新
        if resultMessage.prefix(4) == "http" {
            guideText = resultCall
        } else {
            guideText = resultMessage
        }
        
        if let mp3URL = codeBlock.resultValue(key: guidanceKey, type: .streaming) {
            // online
            reflectImageProcessing(url: URL(string: "http://18.224.144.136/tenji/" + mp3URL)!, message: resultMessage, call: resultCall)
        } else {
            // offline
            guideVoice.offlineReadGuide(manuscript: guideText, lang: codeBlock.language!)
        }
        
        self.code.text = code
        self.angle.text = angle
    }
    
    private func reflectImageProcessing(url: URL, message: String, call: String) {
        guideVoice.onlineReadGuide(mp3URL: url, completion: { initText, delay in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                // 案内文を初期化
                self.guideText = initText
                self.code.text = "\(0)"
                self.angle.text = "\(0)"
                self.guideVoice.process = false
            }
            guard let web = NSURL(string: message) else { return }
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            self.safariVC = SFSafariViewController(url: web as URL, configuration: config)
        })
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
        guideText = NSLocalizedString("Verification", comment: "")
        code.text = "\(0)"
        angle.text = "\(0)"
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
