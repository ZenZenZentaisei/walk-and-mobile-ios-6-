
//
//  InfoViewController.swift
//  BrailleBlockRecognition_iOS
//
//  Created by RyoNishimura on 2021/10/06.
//  Copyright © 2021 matuilab. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    
    var previousVCButton: UIBarButtonItem!

    @IBOutlet weak var versionItemLabel: UILabel!
    @IBOutlet weak var speedItemLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var fontItemLabel: UILabel!
    @IBOutlet weak var fontLabel: UILabel!
    @IBOutlet weak var smallButton: UIButton!
    @IBOutlet weak var mediumButton: UIButton!
    @IBOutlet weak var LargeButton: UIButton!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var decelerateButton: UIButton!
    @IBOutlet weak var accelerationButton: UIButton!

    var fontsize: String = "Medium"
    var loadSpeed: Float = 0.5
    

    var infoCodeData: CodeBlockController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        previousVCButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(previousVCButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = previousVCButton
        
        
        if UserDefaults.standard.float(forKey: "reproductionSpeed") != 0.0 {
            loadSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        }
        
        fontItemLabel.text = NSLocalizedString("Fontsize", comment: "")
        fontsize = UserDefaults.standard.string(forKey: "fontsize") ?? ""
        fontLabel.text = NSLocalizedString(fontsize, comment: "")
        
        smallButton.setTitle("S", for: .normal)
        smallButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        smallButton.titleLabel?.textAlignment = NSTextAlignment.left
        smallButton.titleLabel?.contentMode = .scaleAspectFit
        smallButton.setTitleColor(.black, for: .normal)
        smallButton.backgroundColor = .secondarySystemFill
        smallButton.layer.borderWidth = 1
        smallButton.layer.cornerRadius = 5
        smallButton.layer.masksToBounds = true
        smallButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
        smallButton.addTarget(self, action: #selector(smallDidTapped), for: .touchDown)
        
        mediumButton.setTitle("M", for: .normal)
        mediumButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        mediumButton.titleLabel?.textAlignment = NSTextAlignment.left
        mediumButton.titleLabel?.contentMode = .scaleAspectFit
        mediumButton.setTitleColor(.black, for: .normal)
        mediumButton.backgroundColor = .secondarySystemFill
        mediumButton.layer.borderWidth = 1
        mediumButton.layer.cornerRadius = 5
        mediumButton.layer.masksToBounds = true
        mediumButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
        mediumButton.addTarget(self, action: #selector(mediumDidTapped), for: .touchDown)
        
        LargeButton.setTitle("L", for: .normal)
        LargeButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        LargeButton.titleLabel?.textAlignment = NSTextAlignment.left
        LargeButton.titleLabel?.contentMode = .scaleAspectFit
        LargeButton.setTitleColor(.black, for: .normal)
        LargeButton.backgroundColor = .secondarySystemFill
        LargeButton.layer.borderWidth = 1
        LargeButton.layer.cornerRadius = 5
        LargeButton.layer.masksToBounds = true
        LargeButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
        LargeButton.addTarget(self, action: #selector(largeDidTapped), for: .touchDown)
        
        speedLabel.text = String(loadSpeed)
        speedLabel.accessibilityValue = NSLocalizedString("Playback Speed", comment: "")
       
        decelerateButton.setTitle("−", for: .normal)
        decelerateButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        decelerateButton.titleLabel?.textAlignment = NSTextAlignment.center
        decelerateButton.titleLabel?.contentMode = .scaleAspectFit
        decelerateButton.setTitleColor(.black, for: .normal)
        decelerateButton.backgroundColor = .secondarySystemFill
        decelerateButton.layer.borderWidth = 1
        decelerateButton.layer.cornerRadius = 5
        decelerateButton.layer.masksToBounds = true
        decelerateButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
        decelerateButton.addTarget(self, action: #selector(decelerateDidTapped), for: .touchDown)
        
        accelerationButton.setTitle("+", for: .normal)
        accelerationButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        accelerationButton.titleLabel?.textAlignment = NSTextAlignment.center
        accelerationButton.titleLabel?.contentMode = .scaleAspectFit
        accelerationButton.setTitleColor(.black, for: .normal)
        accelerationButton.backgroundColor = .secondarySystemFill
        accelerationButton.layer.borderWidth = 1
        accelerationButton.layer.cornerRadius = 5
        accelerationButton.layer.masksToBounds = true
        accelerationButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
        accelerationButton.addTarget(self, action: #selector(accelerationDidTapped), for: .touchDown)
        
        appVersionLabel.text = "\(version)"
        appVersionLabel.accessibilityHint = "version"
        
        versionItemLabel.accessibilityHint = "\(version)"
        
        
        speedItemLabel.text = NSLocalizedString("Playback Speed", comment: "")
        speedItemLabel.accessibilityHint = "\(loadSpeed)"
    }
   
    @objc func previousVCButtonTapped(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(round(loadSpeed*100)/100, forKey: "reproductionSpeed")
        UserDefaults.standard.set(fontsize, forKey: "fontsize")
        print(fontsize)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func smallDidTapped(_ sender : Any) {
        fontsize = "Small"
        fontLabel.text = NSLocalizedString(fontsize, comment: "")
    }
    
    @objc func mediumDidTapped(_ sender : Any) {
        fontsize = "Medium"
        fontLabel.text = NSLocalizedString(fontsize, comment: "")
    }
    
    @objc func largeDidTapped(_ sender : Any) {
        fontsize = "Large"
        fontLabel.text = NSLocalizedString(fontsize, comment: "")
    }
    
    @objc func decelerateDidTapped(_ sender : Any) {
        if loadSpeed > 0.1{
            loadSpeed -= 0.10
            speedLabel.text = "\(round(loadSpeed*100)/100)"
        }
    }
    
    @objc func accelerationDidTapped(_ sender : Any) {
        if loadSpeed < 1.0{
            loadSpeed += 0.10
            speedLabel.text = "\(round(loadSpeed*100)/100)"
        }
    }
    
    @IBAction func saveDidTapped(_ sender: Any) {
        guard let setData = infoCodeData else { return }
        setData.saveLocalDataBase() //案内文だけダウンロード
        
        alertDownloadCompleted(title: NSLocalizedString("Latest data", comment: ""),
              message: NSLocalizedString("The latest data could be installed.", comment: ""))
    }
    
    func alertDownloadCompleted(title:String, message:String) {
        var alertController: UIAlertController!
        
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }

}
