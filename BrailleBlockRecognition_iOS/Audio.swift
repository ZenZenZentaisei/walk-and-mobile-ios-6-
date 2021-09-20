//
//  Audio.swift
//  AudioSample
//
//  Created by matuilab on 2020/08/24.
//  Copyright © 2020 matuilab. All rights reserved.
//
import AVFoundation
import Foundation

class Audio {
    
    func readAudio(mp3: String) -> Data{
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var musicData:Data
        let fileURL = documentsPath.appendingPathComponent("\(mp3)")
        
        do{
            musicData = try Data(contentsOf: fileURL)
        }catch {
            musicData = "".data(using: .utf8)!
            print(fileURL)
        }
        return musicData
    }
    func writeAudio(mp3: String){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        //let Url = "http://ec2-3-136-168-45.us-east-2.compute.amazonaws.com/tenji/"
        let Url = "http://54.160.118.189/tenji/"
        let Urlmp3 = Url + mp3
        
        let musicUrl = NSURL(string: Urlmp3)
        let musicData = NSData(contentsOf: musicUrl! as URL)
        if let data = musicData {
            data.write(toFile: "\(documentsPath)/\(mp3)", atomically: true)
        }
        return
    }
    
    func existingFile(mp3: String) -> Bool {

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        
        if let pathComponent = url.appendingPathComponent("\(mp3)") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath){
                return true
            } else {
                return false
            }
        } else {
            return false
            }
    }
    
    func createFolder(addFolder: String){
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
            let folderName = dir.appendingPathComponent( addFolder , isDirectory: true)
            do {
                try FileManager.default.createDirectory( at: folderName, withIntermediateDirectories: true, attributes: nil)
          } catch {
           print("フォルダ作成に失敗 error=\(error)")
          }
        }
    }
}
