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

    @IBOutlet weak var appVersionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        previousVCButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(previousVCButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = previousVCButton
        
        appVersionLabel.text = "\(version) (\(build))"
        
        
    }
    @objc func previousVCButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
