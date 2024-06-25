//
//  VideoStreamViewController.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/21/21.
//

import Cocoa
import MeetingSDK_macOS

class VideoStreamViewController: NSViewController {

    var streamId:String = ""
    var window:NSWindow? = nil
    var participant:Participant? = nil
    
    @IBOutlet weak var rtnPayload: NSTextField!
    @IBOutlet weak var videoArea: NSView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func sendRTNPayload(_ sender: Any) {
        print("SEND RTN PAYLOAD: \(rtnPayload.stringValue) to uuid: \(self.participant?.userUUID ?? "unknown")")
        
        if let destinationUUID = self.participant?.userUUID {
            ModeratorSDK.shared.sendMessage(destinationUUID,rtnPayload.stringValue)
        }
    }
}
