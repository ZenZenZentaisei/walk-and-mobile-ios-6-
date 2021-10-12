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

    @IBOutlet weak var speedStepper: UIStepper!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    var loadSpeed: Float = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        previousVCButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(previousVCButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = previousVCButton
        
        
        if UserDefaults.standard.float(forKey: "reproductionSpeed") != 0.0 {
            loadSpeed = UserDefaults.standard.float(forKey: "reproductionSpeed")
        }
        speedLabel.text = String(loadSpeed)
        speedStepper.value = Double(loadSpeed)
        speedStepper.stepValue = 0.1
        
        appVersionLabel.text = "\(version) (\(build))"
    }
    
    override func viewWillLayoutSubviews() {
        
    }
    @objc func previousVCButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }


    @IBAction func speedAdjustmentDidTapped(_ sender: UIStepper) {
        speedLabel.text = "\(round(sender.value*10)/10)"
        UserDefaults.standard.set(round(sender.value*10)/10, forKey: "reproductionSpeed")
    }
    
}
