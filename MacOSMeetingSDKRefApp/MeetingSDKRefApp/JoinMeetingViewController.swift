//
//  JoinMeetingViewController.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/16/21.
//

import Cocoa
import MeetingSDK_macOS

class JoinMeetingViewController: NSViewController {

    @IBOutlet weak var serverNameTextField: NSTextField!
    @IBOutlet weak var meetingUUIDTextField: NSTextField!
    @IBOutlet weak var userNameTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func doSettings(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if let meetingVC = storyboard.instantiateController(withIdentifier: "SettingsViewController") as? SettingsViewController {
            self.presentAsSheet(meetingVC)
        }
    }
    
    @IBAction func doJoinMeeting(_ sender: Any) {
        let serverName = serverNameTextField.stringValue
        let meetingUUID = meetingUUIDTextField.stringValue
        
        // Simple check to make sure we have the information we need.   If either serverName or
        // meetingUUID are empty, don't continue
        if serverName.count == 0 || meetingUUID.count == 0 || userNameTextField?.stringValue.count == 0 {
            self.alertSheet(text: "Cannot Join", message: "Please make sure server, Meeting UUID, and user name are provided")
            return
        }
        
        // Simple check to make sure that we have an audio input and output device specified in Settings
        if MeetingState.shared.audioInputDeviceName == nil || MeetingState.shared.audioOutputDeviceName == nil {
            self.alertSheet(text: "Cannot Join", message: "Please make sure both an audio input and output device are specified in Settings")
            return
        }
        
        print("Joining Meeting on server \(serverName) with UUID \(meetingUUID)")
        // First, we need to initialize the meeting
        MeetingSDK.shared.initializeMeeting(meetingUUID: meetingUUID, server: serverName) { (success) in
            if !success {
                // There was a problem initializing the meeting
                let lastError = MeetingAPI.sharedInstance().lastError
                print("Initialize Meeting Failure, last error: \(lastError)")
                DispatchQueue.main.async {
                    self.alertSheet(text: "Meeting Initializaion Failure", message: lastError)
                }
            } else {
                //  Proceed with joining the meeting.  We'll load the MeetingViewController
                // object and present it which will keep the process moving
                let storyboard = NSStoryboard(name: "Main", bundle: nil)
                DispatchQueue.main.async {
                    if let meetingVC = storyboard.instantiateController(withIdentifier: "MeetingViewController") as? MeetingViewController {
                        meetingVC.myParticipantName = self.userNameTextField.stringValue

                        let myWindow = NSWindow(contentViewController: meetingVC)
                        myWindow.makeKeyAndOrderFront(self)
                        myWindow.title = "Meeting"
                        let controller = NSWindowController(window: myWindow)
                        controller.showWindow(self)
                        self.view.window?.close()
                    }
                }
            }
        }
    }
    
    // A simple alert sheet
    func alertSheet(text: String, message: String) {
        let a = NSAlert()
        a.messageText = text
        a.informativeText = message
        a.addButton(withTitle: "OK")

        a.alertStyle = .warning
        if let window = self.view.window{
            a.beginSheetModal(for: window, completionHandler: nil)
        }
    }
}

