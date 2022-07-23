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
    @IBOutlet weak var v3Checkbox: NSButton!
    
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
        
        if (self.v3Checkbox.state.rawValue == 0) {
            MeetingSDK.shared.initializeMeeting(meetingUUID: meetingUUID, server: serverName) { (success,key) in
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
                            meetingVC.meetingKey = key
                            meetingVC.meetingUUID = meetingUUID
                            meetingVC.server = serverName
                            meetingVC.isV3Meeting = false
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
        } else {
            // Need to add -api to server name
            
            
            let token = "eyJraWQiOiJaZVJMOFc3U0t5SGkzSXYxUkJqblFIUkRRc1BXWjF0M3pVdWhQTDNjclcwPSIsImFsZyI6IlJTMjU2In0.eyJmZWF0dXJlX2lkIjoiMjM5ZTU4ZGEtOTdjOS00MDI0LWFkMGItODVmMTI0NDE1Yjg3IiwiZmVhdHVyZV9zaGFyZV9oaWdoIjoidHJ1ZSIsImZlYXR1cmVfc2hhcmVfbWVkaXVtIjoiZmFsc2UiLCJ1c2VyX2xhc3RuYW1lIjoiRGlOYXBvbGkiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9FU1lQdkdoTjMiLCJmZWF0dXJlX3ZpZGVvXzEwODBwIjoiZmFsc2UiLCJmZWF0dXJlX2NoYXQiOiJ0cnVlIiwiZmVhdHVyZV92aWV3cyI6IjEwMDAiLCJzdWJzY3JpcHRpb25faWQiOiI3ZmZmMmE1My1hMzc5LTRkNjQtOTBlOS1lZjNkZWM2Zjk2MzciLCJmZWF0dXJlX2hhbmQiOiJmYWxzZSIsImF1dGhfdGltZSI6MTY1NzE5NTQyNSwiZXhwIjoxNjU3MTk5MDI1LCJmZWF0dXJlX3NpcCI6ImZhbHNlIiwiZmVhdHVyZV9wdHoiOiJ0cnVlIiwiZmVhdHVyZV9uYW1lIjoiUFJPIiwidXNlcl9maXJzdG5hbWUiOiJSb24iLCJmZWF0dXJlX3JlY29yZF9yZW1vdGUiOiJ0cnVlIiwiZmVhdHVyZV9maWxlIjoidHJ1ZSIsImNvZ25pdG86dXNlcm5hbWUiOiJmNTZiYWRjNC01ZTY4LTQ2ZjgtODI4ZS0wNzk2YTBhOTYyYTkiLCJmZWF0dXJlX3NoYXJlcyI6IjEwMDAiLCJmZWF0dXJlX2d1ZXN0cyI6IjEwMDAiLCJhdWQiOiI1YWkyZmVlazFyZ3BzbzQ5N29tMWtiajR1ZyIsImZlYXR1cmVfdmlkZW9fbG9zc2xlc3MiOiJ0cnVlIiwidG9rZW5fdXNlIjoiaWQiLCJmZWF0dXJlX3NpemUiOiIxMDAwIiwiZmVhdHVyZV9jYW1lcmFzIjoiMTAwMCIsImZlYXR1cmVfdmlkZW9fOTYwcCI6InRydWUiLCJmZWF0dXJlX3ZpZGVvX2NpZiI6InRydWUiLCJzdWIiOiJmNTZiYWRjNC01ZTY4LTQ2ZjgtODI4ZS0wNzk2YTBhOTYyYTkiLCJmZWF0dXJlX3NoYXJlX2Jlc3QiOiJ0cnVlIiwiZmVhdHVyZV92aWRlb19xY2lmIjoidHJ1ZSIsImZlYXR1cmVfdmlkZW9fdmdhIjoidHJ1ZSIsImZlYXR1cmVfcGl4IjoidHJ1ZSIsImlhdCI6MTY1NzE5NTQyNSwianRpIjoiZjZhZTcxN2MtOWQwZC00MjUwLThkNjMtZjFjYzVlMzcyZGYyIiwiZW1haWwiOiJyZGluYXBvbGlAdmlzaW9uYWJsZS5jb20iLCJ1c2VyX2Rpc3BsYXluYW1lIjoiUm9uIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZlYXR1cmVfc2hhcmVfbG93IjoiZmFsc2UiLCJiaWxsaW5nX2lkIjoiNTcxZmQyMWYtNGQyZC00MGQ2LTkxMGQtODMyNmEzZTRiYTFkIiwiYXNzaWdubWVudF9pZCI6IjYzMThhNTFkLWIxYTQtNDg2Ny05MDJmLTk3YzRjYmUxMjA5NSIsIm9yaWdpbl9qdGkiOiI3ZjM2YmEyMC1mZDhjLTQwNTYtOWYxZi1mZTBiY2ZmMzU2YTkiLCJhY2NvdW50X2lkIjoiNGIxZTNmN2YtMDc4Yi00NzdkLThjNDYtODkzODMwOWM2YmIxIiwiZXZlbnRfaWQiOiI2ZmQxMjBhOC02MTIxLTQ5ZmMtYjE3Zi00MTJjODI4NjA0YzMiLCJmZWF0dXJlX3JlY29yZF9sb2NhbCI6InRydWUiLCJmZWF0dXJlX3BzdG4iOiJ0cnVlIiwiZmVhdHVyZV9oMzIzIjoidHJ1ZSIsImZlYXR1cmVfdmlkZW9fNzIwcCI6InRydWUifQ.ba7g-pgFhbk9ggUz0dMM6T0HzGqr_FwbpAG7rlJnkfTnoRYq-iv7MttRkiwWu0LdCTfqWwZIB7lvxBzqVOz-iJejKhYb7BdTFr3J56_F_OyizjyqsRzpQL1y4Uxfqvu2mbk8IEju7pdO2WuxUKZ6sEA3rFjesySl4S_FVIQQrvjdjwxGcMpFvG8-dnyOV6-xDBMI3W2o4CHkHOTOkmjdexoeRmMfCRROsN0OZhqLx0pl8Rm8mgDPFmKvgrhGbsM7d7_M9jnj4Z5Hgw_PCwmssVGWl7i3iT2it5kU90zvInm5R7HIXT7mzkzc2GaMx9VYSHFl9y1vs3x7AAlj2I52pQ"
            
            MeetingSDK.shared.initializeMeetingWithToken(meetingUUID: meetingUUID, server: serverName, token: nil) { (success,mjwt) in
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
                            meetingVC.meetingKey = mjwt
                            meetingVC.meetingUUID = meetingUUID
                            meetingVC.server = serverName
                            meetingVC.isV3Meeting = true
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

