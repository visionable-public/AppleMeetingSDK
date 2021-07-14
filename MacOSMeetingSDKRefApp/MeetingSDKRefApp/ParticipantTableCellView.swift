//
//  ParticipantTableCellView.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/20/21.
//

import Cocoa
import MeetingSDK_macOS

class ParticipantTableCellView: NSTableCellView {

    @IBOutlet weak var configButton: NSButton!
    
    var participant:Participant? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction func doConfigButton(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if let configVC = storyboard.instantiateController(withIdentifier: "ConfigurationViewController") as? ConfigurationViewController {
            configVC.participant = participant
            
            let myWindow = NSWindow(contentViewController: configVC)
            myWindow.makeKeyAndOrderFront(self)
            myWindow.title = "Configuration"
            
            let userName = self.participant?.displayName ?? "Unknown"
            if self.participant?.isLocal == true {
                myWindow.title = "Configuration for \(userName)(local)"
            } else {
                myWindow.title = "Configuration for \(userName)"
            }
            
            let controller = NSWindowController(window: myWindow)
            controller.showWindow(self)
        }
    }
}
