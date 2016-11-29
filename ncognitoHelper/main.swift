//
//  main.swift
//  ncognitoHelper
//
//  Created by GM on 21/10/2016.
//  Copyright © 2016 Georgios Moustakas. All rights reserved.
//

import Foundation
import GameplayKit

var MACArr = [String]()
var NickArr = [String]()

func createSubFolder() -> Bool {
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else { return false }
    var isDir : ObjCBool = true
    guard let bundleID = Bundle.main.bundleIdentifier else { return false }
    
    if !FileManager.default.fileExists(atPath: String(describing: url.appendingPathComponent(bundleID)), isDirectory: &isDir) {
        
        // folder does not exist
        
        print("Folder \(String(describing: url.appendingPathComponent(bundleID))) does not exist")

        print("creating folder in application support")
        
        do {
            try FileManager.default.createDirectory(at: url.appendingPathComponent(bundleID), withIntermediateDirectories: false, attributes: nil)
            return true
        } catch let error as NSError {
            print(error.description)
            return false
        }
    } else {
        
        // folder exists

        print("folder exists in application support")
    }
    
    return false
}

func moveFile(named: String) -> Bool {
    // Create a FileManager instance
    
    let tempDirPath = URL(fileURLWithPath: "/tmp/\(named)")
    
    let fileManager = FileManager.default
    guard let bundleID = Bundle.main.bundleIdentifier else { return false }
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else { return false }
    
    let appSupPath = url.appendingPathComponent(bundleID + "/" + named)
    
    do {
        try fileManager.moveItem(at: tempDirPath, to: appSupPath)
        return true
    }
    catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
    }
    
    return false
}

func shouldInstall() -> Bool {
    print("checking if application should install files")
    
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else { return false }
    
    guard let   bundleID    = Bundle.main.bundleIdentifier else { return false }
    let         ouiSupPath  = url.appendingPathComponent(bundleID + "/" + "oui.txt")
    let         hostsSupPath  = url.appendingPathComponent(bundleID + "/" + "hosts.txt")

    let         fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: String(describing: ouiSupPath)) {
        print("\(String(describing: ouiSupPath)) does not exist")
        return true
    }
    
    if !fileManager.fileExists(atPath: String(describing: hostsSupPath)) {
        print("\(String(describing: hostsSupPath)) does not exist")
        return true
    }
    
    return false

}

func readoui() -> Int {
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else { return 0 }
    
    guard let   bundleID    = Bundle.main.bundleIdentifier else { return 0 }
    let         appSupPath  = url.appendingPathComponent(bundleID + "/" + "oui.txt")
    
    do {
        let text = try String(contentsOf: appSupPath)
        MACArr = text.components(separatedBy: "\n")
        return MACArr.count
    }
    catch {
        print(error)
    }
    return 0
}

func readhosts() -> Int {
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .localDomainMask).first else { return 0 }
    
    guard let   bundleID    = Bundle.main.bundleIdentifier else { return 0 }
    let         appSupPath  = url.appendingPathComponent(bundleID + "/" + "hosts.txt")
    
    do {
        let text = try String(contentsOf: appSupPath)
        NickArr = text.components(separatedBy: "\n")
        return NickArr.count
    }
    catch {
        print(error)
    }
    return 0
}

func randomHex() -> String {
    let randomInt = GKRandomSource.sharedRandom().nextInt(upperBound: 16)
    let string1 = String(randomInt, radix: 16)
    return string1
}

func rightMAC() -> String {
    return randomHex() + randomHex() + ":" + randomHex() + randomHex() + ":" + randomHex() + randomHex()
}

func newRandomMAC() -> String {
    let lines = readoui()
    
    if lines == 0 {
        return ""
    }

    
    let randomInt = GKRandomSource.sharedRandom().nextInt(upperBound: lines)
    let randomMAC = MACArr[randomInt] + ":" + rightMAC()
    
    return randomMAC
}

func newRandomHostname() -> String {
    let lines = readhosts()
    
    if lines == 0 {
        return ""
    }

    let randomInt = GKRandomSource.sharedRandom().nextInt(upperBound: lines)
    let randomNickname = NickArr[randomInt]
    
    return randomNickname
}

func shell(args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func getIffs() -> [String] {
    var theoutput = [String]()
    do {
        let script = "ifconfig | expand | cut -c1-8 | sort | uniq -u | awk -F: '{print $1;}'"
        
        let myAppleScript = "do shell script " + "\"\(script)\""
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                
                theoutput = (output.stringValue?.components(separatedBy: "\r"))!
            } else if (error != nil) {
                print("error: \(error)")
            }
        }
    }
    catch {
        print(error)
    }
    
    return theoutput
}

func printDate() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
    print("----------------" + formatter.string(from: NSDate() as Date), terminator: "" + "----------------")

    
}

/*
 *
 * App Logic
 *
 */

printDate()


if shouldInstall() {
    print("Installing application files")
    
    if createSubFolder() {
        print("successfully created folder in Application Support directory")
    }
    
    if moveFile(named: "oui.txt") && moveFile(named: "hosts.txt") {
        print("successfully copied oui.txt and hosts.txt to Application Support Directory")
    }
}

// Change MAC
let iffs = getIffs()

for iff in iffs {
    let randomMAC = newRandomMAC()
    shell(args: "ifconfig", iff ,"ether", randomMAC)
}

// Change Hostname

let randomHostname = newRandomHostname()
shell(args: "scutil", "--set", "HostName", randomHostname)
shell(args: "scutil", "--set", "LocalHostName", randomHostname)
shell(args: "scutil", "--set", "ComputerName", randomHostname)
