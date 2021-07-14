//
//  SettingsViewController.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/16/21.
//
//  A very simple Settings view controller.    Dynamically creates a list
//  of video devices and audio input/output devices to choose from.
//  Simply stores selected values in MeetingState singleton.   A real settings
//  controller would likely use NSUserDefaults to store selections
//

import Cocoa
import MeetingSDK_macOS

class SettingsViewController: NSViewController {

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    var audioInputMenu:NSPopUpButton? = nil
    var audioOutputMenu:NSPopUpButton? = nil
    var videoCodecs:[String:NSPopUpButton] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        contentView.layer?.backgroundColor = NSColor.blue.cgColor
        
        // First, get an array of video devices
        let videoDevices = MeetingSDK.shared.getVideoDevices()
        let audioInputDevices = MeetingSDK.shared.getAudioInputDevices()
        let audioOutputDevices = MeetingSDK.shared.getAudioOutputDevices()
        let boldAttributes:[NSAttributedString.Key:Any] =  [ .font : NSFont.boldSystemFont(ofSize:12) ]
        
        // First three entries are always the same
        
        audioOutputMenu = NSPopUpButton(frame:CGRect(x: 5, y: 0, width: 345, height: 20))
        var audioOutputOptions = [ "None" ]
        audioOutputOptions.append(contentsOf: audioOutputDevices)
        audioOutputMenu?.addItems(withTitles: audioOutputOptions)
        if let outputMenu = audioOutputMenu {
            contentView.addSubview(outputMenu)
        }
        
        var label = NSTextField(frame:CGRect(x: 10, y: 20, width: 360, height: 20))
        label.stringValue = "Output:"
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .gridColor
        contentView.addSubview(label)
 
        audioInputMenu = NSPopUpButton(frame:CGRect(x: 5, y: 50, width: 345, height: 20))
        var audioInputOptions = [ "None" ]
        audioInputOptions.append(contentsOf: audioInputDevices)
        audioInputMenu?.addItems(withTitles: audioInputOptions)
        if let inputMenu = audioInputMenu {
            contentView.addSubview(inputMenu)
        }

        label = NSTextField(frame:CGRect(x: 10, y: 70, width: 360, height: 20))
        label.stringValue = "Input:"
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .gridColor
        contentView.addSubview(label)

        label = NSTextField(frame:CGRect(x: 10, y: 90, width: 360, height: 20))
        label.attributedStringValue = NSAttributedString(string: "Audio Devices:", attributes: boldAttributes)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .gridColor
        contentView.addSubview(label)

        for i in 0..<videoDevices.count {
            // Add popup
            let popupMenu = NSPopUpButton(frame:CGRect(x: 5, y: (i*50)+130, width: 345, height: 20))
            var codecArray = [ "Not Used" ]
            codecArray.append(contentsOf: MeetingSDK.shared.getSupportedVideoSendResolutions(deviceId: videoDevices[i]))
            popupMenu.addItems(withTitles: codecArray)
            contentView.addSubview(popupMenu)
            // Add the popup menu to the dictionary
            videoCodecs[videoDevices[i]] = popupMenu
            
            // Now "heading"
            let label = NSTextField(frame:CGRect(x: 10, y: (i*50)+150, width: 360, height: 20))
            label.stringValue = "\(videoDevices[i])"
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .gridColor
            contentView.addSubview(label)
        }
        
        label = NSTextField(frame:CGRect(x: 10, y: (videoDevices.count*50    )+120, width: 360, height: 20))
        label.attributedStringValue = NSAttributedString(string: "Video Devices:", attributes: boldAttributes)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .gridColor
        contentView.addSubview(label)

        let origin = contentView.frame.origin
        let size = contentView.frame.size
        let height = ((videoDevices.count) * 50)+155
        // Set size of scroll view content frame.   Multiple 30 points by the number of entries to display + 2 (for labels)
        contentView.frame = CGRect(x: origin.x, y: origin.y, width: size.width, height: CGFloat(height))
        
        if let documentView = scrollView.documentView {
                documentView.scroll(NSPoint(x: 0, y: documentView.bounds.size.height))
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        self.dismiss(self)
        
        // We'll need to save the following:
        if let inputDevice = audioInputMenu?.titleOfSelectedItem {
            print("Setting audio input device to \(inputDevice)")
            MeetingState.shared.audioInputDeviceName = inputDevice
        }
        
        if let outputDevice = audioOutputMenu?.titleOfSelectedItem {
            print("Setting audio output device to \(outputDevice)")
            MeetingState.shared.audioOutputDeviceName = outputDevice
        }
        
        // Clear any existing video devices in the MeetingState singleton
        MeetingState.shared.resetVideoDevices()
        for (device, codecMenu) in videoCodecs {
            if let codecSelected = codecMenu.titleOfSelectedItem {
                if codecSelected == "Not Used" {
                    print("\(device) is turned off")
                } else {
                    print("Adding video device: \(device) with codec: \(codecSelected)")
                    MeetingState.shared.addVideoDevice(deviceName: device, codec: codecSelected)
                }
            }
        }
    }
    
    @IBAction func doCancel(_ sender: Any) {
        // Simple dismiss without saving if cancel button clicked
        self.dismiss(self)
    }
}
