//
//  Audio.swift
//  BrailleBlockRecognition
//
//  Created by matuilab on 2020/08/24.
//  Copyright © 2020 matuilab. All rights reserved.
//

import Foundation

class Audio {
    func readAudio(mp3: String) -> Data{
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(mp3)
        var musicData:Data
        
        do{
            musicData = try Data(contentsOf: fileURL)
        }catch {
            musicData = "".data(using: .utf8)!
        }
        return musicData
    }
    
    func writeAudio(mp3: String){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let Url = "http://ec2-3-136-168-45.us-east-2.compute.amazonaws.com/tenji/message/"
        
        let Urlmp3 = Url + mp3
        let musicUrl = NSURL(string: Urlmp3)
        let musicData = NSData(contentsOf: musicUrl! as URL)
        if let data = musicData {
            data.write(toFile: "\(documentsPath)/\(mp3)", atomically: true)
        }
        return
    }
    
    func existingFile(fileName: String) -> Bool {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("\(fileName)") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath)
           {
            return true
            } else {
            return false
            }
        } else {
            return false
            }
    }
}

