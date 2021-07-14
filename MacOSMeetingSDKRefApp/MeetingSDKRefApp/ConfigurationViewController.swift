//
//  ConfigurationViewController.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/20/21.
//

import Cocoa
import MeetingSDK_macOS

class ConfigurationViewController: NSViewController {

    var participant:Participant? = nil
    
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var mediaView: NSView!
    @IBOutlet weak var mediaViewHeightConstraint: NSLayoutConstraint!
    
    // Used to keep track of which popup menu refers to which local video device
    fileprivate var videoPopUpMenuMappings:[NSPopUpButton:String]=[:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.rebuildUI()
    }
    
    // Utility function to find the latest participant structure based on the copy we already have
    // (used to get updates to the participant object stored in the SDK)
    func updateParticipant(_ participant:Participant?)
    {
        // We need to find a stream ID to identify the participant in the SDK store.  Audio is preferred
        // but not always available
        if let audioInfo = participant?.audioInfo {
            // We have an audioInfo, so we should have a stream id
            
            if let updatedParticipant = MeetingSDK.shared.findParticipant(withAudioStreamId: audioInfo.streamId) {
                self.participant = updatedParticipant
                return
            }
        }
        
        // OK, we need to try and find a participant based on video stream
        if let videoInfoArray = participant?.videoInfo {
            
            // Check each video stream id in succession
            for videoInfo in videoInfoArray {
                // Make sure we get a participant back.    If the remote user disabled this video
                // stream before we make this call, we'll get nil back from the findParticipant call
                if let updatedParticipant = MeetingSDK.shared.findParticipant(withVideoStreamId: videoInfo.streamId) {
                    self.participant = updatedParticipant
                    return
                }
            }
        }
        
        // This should never happen, if we get down here it means that we were unable to locate
        // a participant.
    }
    
    @objc func doAudioSlider(_ sender: NSSlider) {
        print("doAudioSlider: value: \(sender.integerValue)")
        if let streamId = self.participant?.audioInfo?.streamId {
            let newAudioValue = sender.integerValue
            MeetingState.shared.audioStreamVolumes[streamId] = newAudioValue
            
            // Set level through SDK
            MeetingSDK.shared.setAudioStreamVolume(streamId: streamId, volume: Int32(newAudioValue))
        }
    }
    
    @objc func doLocalVideoPopup(_ sender: NSPopUpButton) {
        if let device = self.videoPopUpMenuMappings[sender] {
            if let selectedCodec = sender.titleOfSelectedItem {
                if selectedCodec == "Not Used" {
                    MeetingSDK.shared.disableVideoCapture(camera: device)
                } else {
                    MeetingSDK.shared.disableVideoCapture(camera: device)
                    // Give time to disable, dispatch enable on main queue
                    DispatchQueue.main.async {
                        MeetingSDK.shared.enableVideoCapture(camera: device, withMode: selectedCodec) { (success) in
                            // TBD
                        }
                    }
                }
            }
        }

    }
    
    
    func rebuildUIForLocalUser() {
        let videoDevices = MeetingSDK.shared.getVideoDevices()
        var yOffset:CGFloat = 0.0
        self.videoPopUpMenuMappings.removeAll()
        
        // It's a local user, see if we have the name in the first video object of participant
        if let userName = self.participant?.displayName
        {
            userNameLabel.stringValue = "\(userName) (local)"
            self.view.window?.title = "Configuration for \(userName)"
        }
        
        for device in videoDevices {
            let rect = CGRect(x: 0.0, y: yOffset, width: mediaView.frame.width, height: 30.0)
            let view = NSView(frame:rect)
            
            let labelRect = CGRect(x: 5.0, y: 5.0, width: mediaView.frame.width-200.0, height: 20.0)
            let label = NSTextField(frame:labelRect)
            label.stringValue = device
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            
            let popupMenu = NSPopUpButton(frame:CGRect(x: mediaView.frame.width - 190, y: 5.0, width: 180, height: 20.0))
            var codecArray = [ "Not Used" ]
            codecArray.append(contentsOf: MeetingSDK.shared.getSupportedVideoSendResolutions(deviceId: device))
            popupMenu.addItems(withTitles: codecArray)
            popupMenu.action = #selector(doLocalVideoPopup(_:))
            self.videoPopUpMenuMappings[popupMenu] = device
            
            // Set the value of the popup to the proper setting
            if let codec = MeetingState.shared.videoDevicesUsed?[device] {
                popupMenu.setTitle(codec)
            }
            view.addSubview(label)
            view.addSubview(popupMenu)
            mediaView?.addSubview(view)
            yOffset = yOffset + 30
        }
    }
    
    
    func rebuildUI() {
        userNameLabel.stringValue = "Some user"
        
        var yOffset:CGFloat = 0.0
        
        // First, update the participant object based on a known stream ID (preferably audio)
        self.updateParticipant(self.participant)
        
        //  Remove any existing subviews from the mediaView view
        for subview in self.mediaView.subviews {
            subview.removeFromSuperview()
        }
        
        if participant?.isLocal == true {
            return rebuildUIForLocalUser()
        }
        
        // Rebuild UI
        if let audioInfo = participant?.audioInfo {
            
            userNameLabel.stringValue = participant?.displayName ?? "Unknown"
            
            // Add rectangle to mediaView for audio
            let rect = CGRect(x: 0.0, y: 0.0, width: mediaView.frame.width, height: 30.0)
            let view = NSView(frame:rect)
            
            let labelRect = CGRect(x: 5.0, y: 5.0, width: 80.0, height: 20.0)
            let label = NSTextField(frame:labelRect)
            label.stringValue = "Audio Level:"
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            
            let sliderRect = CGRect(x: 85.0, y: 0.0, width: self.mediaView.frame.size.width - 100, height: 30.0)
            let slider = NSSlider(frame: sliderRect)
            
            slider.minValue = 0
            slider.maxValue = 100
            slider.integerValue = MeetingState.shared.audioStreamVolumes[audioInfo.streamId] ?? 50
            slider.target = self
            slider.action = #selector(doAudioSlider(_:))
            
            view.addSubview(label)

            view.addSubview(slider)
            mediaView?.addSubview(view)
            
            yOffset = 30.0
        }
        
        if let videoInfoArray =  participant?.videoInfo {
            for videoInfo in videoInfoArray {
                let rect = CGRect(x: 0.0, y: yOffset, width: mediaView.frame.width, height: 30.0)
                let view = NSView(frame:rect)
                
                let labelRect = CGRect(x: 5.0, y: 5.0, width: mediaView.frame.width-100.0, height: 20.0)
                let label = NSTextField(frame:labelRect)
                label.stringValue = videoInfo.name
                label.isEditable = false
                label.isBordered = false
                label.backgroundColor = .clear
                
                
                let buttonRect = CGRect(x: mediaView.frame.width - 90, y: 5.0, width: 80, height: 20.0)
                let button = NSButton(frame: buttonRect)
                
                if videoInfo.active == "true" {
                    button.title = "Disable"
                } else {
                    button.title = "Enable"
                }
                button.tag = Int(videoInfo.streamId) ?? 0
                button.action = #selector(enablePushed(_:))
                
                button.bezelStyle = .rounded
                button.setButtonType(.momentaryLight)
                
                print("VIDEO: \(videoInfo.streamId)")
                
                view.addSubview(label)
                view.addSubview(button)
                mediaView?.addSubview(view)
                yOffset = yOffset + 30
            }
        }
        
        mediaViewHeightConstraint.constant = yOffset
    }
    
    @objc func enablePushed(_ sender: NSButton) {
        let streamId = String(sender.tag)

        print("enablePushed: \(sender) for streamId: \(streamId)")

        if sender.title == "Disable" {
            sender.title = "Enable"
            MeetingSDK.shared.disableVideoStream(streamId: streamId)
            
            for videoStreamVC in MeetingState.shared.videoWindows {
                if videoStreamVC.streamId == streamId {
                    videoStreamVC.window?.orderOut(self)
                    return
                }
            }
        } else {
            sender.title = "Disable"
            MeetingSDK.shared.enableVideoStream(participant: self.participant!, streamId: streamId)
        }
    }
    
    @IBAction func doDoneButton(_ sender: Any) {
        self.view.window?.close()
    }
}
