//
//  Config.swift
//  BrailleBlockRecognition_iOS
//
//  Created by matuilab on 2020/11/24.
//  Copyright © 2020 matuilab. All rights reserved.
//

import Foundation
import UIKit

class Config: UIViewController {
    var resultHandler: ((Bool) -> Void)?
    var configBool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config.setOn(configBool, animated: false)
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var config: UISwitch!
    @IBAction func config_func(_ sender: Any) {
        configBool = (sender as AnyObject).isOn
        if let handler = self.resultHandler {
            // 入力値を引数として渡された処理の実行
            handler(configBool)
        }
    }
}
