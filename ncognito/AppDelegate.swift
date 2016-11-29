//
//  AppDelegate.swift
//  ncognito
//
//  Created by GM on 21/10/2016.
//  Copyright © 2016 Georgios Moustakas. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var infoLabel: NSTextField!

    @IBOutlet weak var window: NSWindow!
    var textArr = [String]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        infoLabel.stringValue = ""
    }
    
    @IBAction func install(_ sender: AnyObject) {
        
        if moveOUIToTempDir() && movehostsToTempDir() {
            print("copied oui.txt and hosts.txt to temp directory")
        }

        if installDaemon() {
            infoLabel.stringValue = "Installed successfully!"
        }
        else {
            infoLabel.stringValue = "Problem Installing"
        }
    }
    
    @IBAction func purge(_ sender: AnyObject) {

        guard let shScriptPath = Bundle.main.url(forResource: "Uninstall", withExtension: "sh") else {
            print("problem")
            return
        }

        do {
            var script = try String(contentsOf: shScriptPath)
            script = script.replacingOccurrences(of: "\\", with: "\\\\")

            let myAppleScript = "do shell script " + "\"\(script)\"" + " with administrator privileges"
            
            print(myAppleScript)

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: myAppleScript) {
                if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                    &error) {
                    print(output.stringValue)
                } else if (error != nil) {
                    print("error: \(error)")
                }
            }
        }
        catch {
            print(error)
        }
        infoLabel.stringValue = "Uninstalled successfully!"

    }
    
    func installDaemon() -> Bool {
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper,
                                         valueLength: 0, value: nil, flags: 0)
        
        var myRights = AuthorizationRights(count: 1, items: &authItem)
        
        let myFlags : AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights ]
        
        var authRef: AuthorizationRef?
        let osStatus = AuthorizationCreate(&myRights, nil, myFlags, &authRef)
        
        if osStatus == errAuthorizationSuccess {
            var error: Unmanaged<CFError>?
            SMJobBless(kSMDomainSystemLaunchd, "com.giorgosmoustakas.ncognitoHelper" as CFString, authRef, &error)
            // also kSMDomainUserLaunchd
            
            if (error != nil) {
                print(error)
                return false
            }
        }
        else {
            return false
        }
        return true
    }
    
    
    func moveOUIToTempDir() -> Bool {
        // Create a FileManager instance
        
        guard let ouiPath = Bundle.main.url(forResource: "oui", withExtension: "txt") else { return false }
        
        let fileManager = FileManager.default
        
        let tempDirPath = URL(fileURLWithPath: "/tmp/oui.txt")
        
        print(tempDirPath)
        
        do {
            try fileManager.moveItem(at: ouiPath, to: tempDirPath)
            return true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        return false
    }
    
    func movehostsToTempDir() -> Bool {
        // Create a FileManager instance
        
        guard let ouiPath = Bundle.main.url(forResource: "hosts", withExtension: "txt") else { return false }
        
        let fileManager = FileManager.default
        
        let tempDirPath = URL(fileURLWithPath: "/tmp/hosts.txt")
        
        print(tempDirPath)
        
        do {
            try fileManager.moveItem(at: ouiPath, to: tempDirPath)
            return true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        return false
    }
    
    func deleteFile(fileURL: URL) -> Bool {
        let fileManager = FileManager.default

        do {
            try fileManager.removeItem(at: fileURL)
            return true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        return false
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

