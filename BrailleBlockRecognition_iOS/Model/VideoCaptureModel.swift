import AVFoundation


protocol VideoCaptureDelegate: AnyObject {
//    func didSet(_ display: UIImage)
    func didCaptureFrame(display: UIImage, code: String, angle: String)
}

class VideoCaptureModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: VideoCaptureDelegate?
    
    private var captureSession: AVCaptureSession! //セッション
    private var device: AVCaptureDevice! //カメラ
    private var output: AVCaptureVideoDataOutput! //出力先
    
    
    public func startCapturing() {
        // セッションの作成.
        captureSession = AVCaptureSession()
        // 解像度の指定.
        captureSession.sessionPreset = .photo
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
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
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
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            return
        }

        // カメラの向きを合わせる
        for connection in output.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        captureSession.startRunning()
    }
    
    public func stopCapturing() {
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            let img = self.captureImage(sampleBuffer) //UIImageへ変換
            self.openCVImageProcessing(image: img)
        }
    }
    
    private func openCVImageProcessing(image: UIImage) {
        let openCV = OpenCV()
        // 初期化(↓しないと何故か状態を保存し、更新されない)
        openCV.reader(UIImage(named: "sample"))! as NSArray
        
        let result = openCV.reader(image)! as NSArray
            
        let imageResult = result[0] as! UIImage
        let codeResult = result[1] as! Int
        let angleResult = result[2] as! Int
        
        delegate?.didCaptureFrame(display: imageResult, code: "\(codeResult)", angle: "\(angleResult)")
    }
    
    // sampleBufferからUIImageを作成
    private func captureImage(_ sampleBuffer:CMSampleBuffer) -> UIImage {
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
