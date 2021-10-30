
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
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var decelerateButton: UIButton!
    @IBOutlet weak var accelerationButton: UIButton!
    
    var loadSpeed: Float = 1.0

    var infoCodeData: CodeBlockController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        previousVCButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(previousVCButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = previousVCButton
        
        
        if UserDefaults.standard.float(forKey: "reproductionSpeed") != 0.0 {
            loadSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        }
        
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
        decelerateButton.accessibilityValue = "\(loadSpeed - 0.1)"
        
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
        accelerationButton.accessibilityValue = "\(loadSpeed + 0.1)"
        
        appVersionLabel.text = "\(version)"
        appVersionLabel.accessibilityHint = "version"
        
        versionItemLabel.accessibilityHint = "\(version)"
        
        speedItemLabel.text = NSLocalizedString("Playback Speed", comment: "")
        speedItemLabel.accessibilityHint = "\(loadSpeed)"
    }
   
    @objc func previousVCButtonTapped(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(round(loadSpeed*10)/10, forKey: "reproductionSpeed")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func decelerateDidTapped(_ sender : Any) {
        loadSpeed -= 0.1
        speedLabel.text = "\(round(loadSpeed*10)/10)"
    }
    
    @objc func accelerationDidTapped(_ sender : Any) {
        loadSpeed += 0.1
        speedLabel.text = "\(round(loadSpeed*10)/10)"
    }
    
    @IBAction func saveDidTapped(_ sender: Any) {
        guard let setData = infoCodeData else { return }
        setData.saveLocalDataBase()
        alertDownloadCompleted(title: NSLocalizedString("Latest data", comment: ""),
              message: NSLocalizedString("I was able to install the latest data.", comment: ""))
    }
    
    func alertDownloadCompleted(title:String, message:String) {
        var alertController: UIAlertController!
        
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }

}
