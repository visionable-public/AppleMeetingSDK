//
//  MeetingViewController.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/16/21.
//

import Cocoa
import MeetingSDK_macOS

class MeetingViewController: NSViewController, MeetingSDKDelegate, NSTableViewDelegate, NSTableViewDataSource {
    var myParticipantName = ""
    var participantArray:[Participant] = []
    var mutedStreamIDs:[String:Bool] = [:]
    
    @IBOutlet weak var participantTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Set delegate
        MeetingSDK.shared.delegate = self
        MeetingSDK.shared.joinMeeting(name: myParticipantName) { (success) in
            if success {
                print("join command succeeded, enabling local audio/video")
                self.enableOutgoingAudioVideo()
                
                // Local user should be in the participants array now, reload table
                self.participantArray = MeetingSDK.shared.participants
                DispatchQueue.main.async {
                    self.participantTableView.reloadData()
                }
            } else {
                print("join command failed: \(MeetingAPI.sharedInstance().lastError)")
            }
        }
    }
    
    // This function sets up our outgoing audio and video and begins sending it to
    // the remote meeting
    func enableOutgoingAudioVideo() {
        
        MeetingState.shared.printAudioVideoSettings()
        
        if let audioInput = MeetingState.shared.audioInputDeviceName {
            if audioInput != "None" {
                // We've got a real audio input device, use it!
                MeetingSDK.shared.enableAudioInput(device: audioInput)
            }
        }
        
        if let audioOutput = MeetingState.shared.audioOutputDeviceName {
            if audioOutput != "None" {
                MeetingSDK.shared.enableAudioOutput(device: audioOutput)
            }
        }
        
        // Enable video devices
        if let videoDevices = MeetingState.shared.videoDevicesUsed {
            // We need to "chain" the enabling of multiple video devices.  Don't try
            // to enable a "next" device until the "previous" one finishes enabling
            enableNextVideoDevice(devices: videoDevices)
        }
    }
    
    private func enableNextVideoDevice(devices:[String:String]?) {
        // Make sure there is a device to enable.  If not, do nothing
        if let (device,codec) = devices?.first {
            print("enableOutgoingAudioVideo:: Attempting to enable capture on device \(device) with codec \(codec)")
            // Dispatch to main queue to avoid problem with a multiple input devices
            DispatchQueue.main.async {
                MeetingSDK.shared.enableVideoCapture(camera: device, withMode: codec) { (success) in
                    if success {
                        print("Successfully enabled \(device) with mode: \(codec)")
                        
                        // Remove the current "first" device from the list of devices to enable
                        // and then enable the next device
                        var remainingDevices = devices
                        remainingDevices?.removeValue(forKey: device)
                        self.enableNextVideoDevice(devices: remainingDevices)
                    } else {
                        let text = "Error enabling \(device) with mode: \(codec)"
                        
                        DispatchQueue.main.async {
                            self.alertSheet(text: text, message: MeetingAPI.sharedInstance().lastError)
                        }
                        // lastError needs to be bubbled up to MeetingSDK
                        print(text)
                        print("Error: \(MeetingAPI.sharedInstance().lastError)")
                    }
                }
            }
        }
    }
    
    @IBAction func doExitMeeting(_ sender: Any) {
        
        // First, close all video stream windows
        for videoStreamVC in MeetingState.shared.videoWindows {
            videoStreamVC.view.window?.close()
        }
        
        let mainStoryboard = NSStoryboard.init(name: "Main", bundle: nil)
        let mainWindowController = mainStoryboard.instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
        mainWindowController.showWindow(self)
        
        MeetingSDK.shared.exitMeeting()
        self.view.window?.close()
    }
    
    @IBAction func doMuteToggle(_ sender: NSButton) {
        if sender.title == "Mute Me" {
            MeetingSDK.shared.disableAudioInput(device: MeetingState.shared.audioInputDeviceName ?? "")
            sender.title = "Unmute Me"
        } else {
            MeetingSDK.shared.enableAudioInput(device: MeetingState.shared.audioInputDeviceName ?? "")
            sender.title = "Mute Me"
        }
    }
    
    @IBAction func doVideoToggle(_ sender: NSButton) {
        if sender.title == "Video Off" {
            if let videoDevicesUsed = MeetingState.shared.videoDevicesUsed {
                for (name,_) in videoDevicesUsed {
                    MeetingSDK.shared.disableVideoCapture(camera: name)
                }
            }
            sender.title = "Video On"
                
        } else {
            // Enable video devices
            if let videoDevices = MeetingState.shared.videoDevicesUsed {
                // We need to "chain" the enabling of multiple video devices.  Don't try
                // to enable a "next" device until the "previous" one finishes enabling
                enableNextVideoDevice(devices: videoDevices)
            }
            
            sender.title = "Video Off"
        }
    }
    @IBAction func doAudioInputSlider(_ sender: NSSlider) {
        let newInputLevel = sender.integerValue
        MeetingSDK.shared.setAudioInputVolume(Int32(newInputLevel))
    }
    
    @IBAction func doAudioOutputSlider(_ sender: NSSlider) {
        let newOutputLevel = sender.integerValue
        MeetingSDK.shared.setAudioOutputVolume(Int32(newOutputLevel))
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
    
    // MARK: -
    // MARK: MeetingSDK Delegate Methods
    func participantAdded(participant: Participant) {
        if let audioInfo = participant.audioInfo {
            // Add default audio level for this stream into array in MeetingState
            MeetingState.shared.audioStreamVolumes[audioInfo.streamId] = 50
        }
        
        print("MeetingSDKDelegate:  participantAdded: \(participant.displayName), total count now \(MeetingSDK.shared.participants.count)")
        DispatchQueue.main.async {
            self.participantArray = MeetingSDK.shared.participants
            
            print("-------\nUpdating participant list based on data: \(self.participantArray)\n-------")
            self.participantTableView.reloadData()
        }
    }
    
    func participantVideoAdded(participant: Participant, streamId: String) {
        MeetingSDK.shared.enableVideoStream(participant: participant, streamId: streamId)
        print("MeetingSDKDelegate:  participantVideoAdded (\(participant.displayName)), streamId: \(streamId)")
    }
    
    func participantVideoUpdated(participant: Participant, streamId: String, videoView: VideoView) {
        print("MeetingSDKDelegate:  participantVideoUpdated")
    }
    
    func participantVideoViewCreated(participant: Participant, videoView: VideoView, local: Bool) {
        // Since the reference app wants to store the streamId with the window it will create,
        // we need to iterate through all the VideoInfo objects for this participant and find
        // the one corresponding to the VideoView just created.  Then we can pass the right streamId
        for videoInfo in participant.videoInfo {
            if videoInfo.videoView == videoView {
                spawnWindow(videoInfo.videoView!, streamId: videoInfo.streamId)
            }
        }
        
        print("MeetingSDKDelegate: participantVideoViewCreated (\(participant.displayName))")
    }
    
    func participantVideoViewRetrieved(participant: Participant, videoView: VideoView) {
        print("MeetingSDKDelegate:  participantVideoViewRetrieved")
        // If this window was put in the background/hidden because the stream was disabled,
        // we need to bring it back to the foreground
        if let streamId = participant.videoInfo.first?.streamId {
            for videoStreamVC in MeetingState.shared.videoWindows {
                if videoStreamVC.streamId == streamId {
                    videoStreamVC.window?.orderFront(self)
                }
            }
        }
    }
    
    func particpantVideoRemoteLayoutChanged(participant: Participant, streamId: String) {
        print("MeetingSDKDelegate:  particpantVideoRemoteLayoutChanged")
    }
    
    func participantVideoRemoved(participant: Participant, streamId: String, videoView: VideoView?) {
        var name = "Unknown"
        
        for videoInfo in participant.videoInfo {
            if videoInfo.streamId == streamId {
                name = videoInfo.site
                self.removeWindow(videoInfo.streamId)
            }
        }


        print("MeetingSDKDelegate:  participantVideoRemoved (\(name))")
    }
    
    func participantRemoved(participant: Participant) {
        print("MeetingSDKDelegate:  participantRemoved: \(participant.displayName), total count now \(MeetingSDK.shared.participants.count)")
        DispatchQueue.main.async {
            self.participantArray = MeetingSDK.shared.participants
            self.participantTableView.reloadData()
        }
        
        // Remove all video windows
        for videoInfo in participant.videoInfo {
            self.removeWindow(videoInfo.streamId)
        }
    }
    
    func inputMeterChanged(meter: String) {
        print("MeetingSDKDelegate:  inputMeterChanged")
    }
    
    func outputMeterChanged(meter: String) {
        print("MeetingSDKDelegate:  outputMeterChanged")
    }
    
    func participantAmplitudeChanged(participant: Participant, amplitude: String, muted: Bool) {
        if let streamId = participant.audioInfo?.streamId {
            if muted {
                self.mutedStreamIDs[streamId] = true
            } else {
                self.mutedStreamIDs.removeValue(forKey: streamId)
            }
            
            DispatchQueue.main.async {
                self.participantTableView.reloadData()
            }

        }
        print("MeetingSDKDelegate:  amplitude")
    }
    
    // MARK: -
    // MARK: NSTableViewDelegate Methods
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
    
    // MARK: -
    // MARK: NSTableViewDataSource Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        // Return number of participants + 1 for the user
        let rowCount = participantArray.count
        print("MeetingSDKDelegate:  there are going to be \(rowCount) rows in the table")
        return rowCount
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var name1 = ""
        var name2 = ""
        
        participantArray.sort { (first:Participant, second:Participant) -> Bool in
            /*
            if first.videoInfo.count == 0 {
                guard let audioSite = first.audioInfo?.site else {
                    return false
                }
                name1 = audioSite
            } else {
                name1 = first.videoInfo[0].site
            }
            
            if second.videoInfo.count == 0 {
                guard let audioSite = second.audioInfo?.site else {
                    return false
                }
                name2 = audioSite
            } else {
                name2 = second.videoInfo[0].site
            }
 */
            
            return first.displayName < second.displayName
        }
        
        let name = participantArray[row].displayName
    
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ParticipantCell"), owner: nil) as? ParticipantTableCellView {
          cell.participant = participantArray[row]
        
            cell.textField?.stringValue = name
            
            // Now check to see if it's muted and change accordingly
            if let audioInfo = cell.participant?.audioInfo {
                if let muted = self.mutedStreamIDs[audioInfo.streamId] {
                    if muted {
                        cell.textField?.stringValue = "(M) \(name)"
                    }
                }
            }
          return cell
        }
        return nil
    }
    
    // MARK: -
    // MARK: Window Management
    
    func spawnWindow(_ view:VideoView, streamId: String) {
        DispatchQueue.main.async {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: Bundle.main)
            if let vc = storyboard.instantiateController(withIdentifier: "VideoStream") as? VideoStreamViewController
            {
                vc.view.addSubview(view)
                
                // Add constraints
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint(item: view as Any, attribute: .leading, relatedBy: .equal, toItem: vc.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: view as Any, attribute: .trailing, relatedBy: .equal, toItem: vc.view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: view as Any, attribute: .top, relatedBy: .equal, toItem: vc.view, attribute: .top, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: view as Any, attribute: .bottom, relatedBy: .equal, toItem: vc.view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
                print("compression: \(NSLayoutConstraint.Priority.defaultLow)")
                
                // Setting the compression resistance priority allows us to resize the window smaller
                // than the size of the video frames coming in
                view.frameView?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                view.frameView?.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                
                let myWindow = NSWindow(contentViewController: vc)
                myWindow.makeKeyAndOrderFront(self)
                let controller = NSWindowController(window: myWindow)
                controller.showWindow(self)

                vc.streamId = streamId
                vc.window = myWindow
                
                if let videoInfo = MeetingSDK.shared.findVideoInfo(streamId: streamId) {
                    myWindow.title = "\(videoInfo.site) -- \(videoInfo.name)"
                }
                
                MeetingState.shared.videoWindows.append(vc)
            }
        }
    }

    
    func removeWindow(_ streamId:String) {
        for videoStreamVC in MeetingState.shared.videoWindows {
            if videoStreamVC.streamId == streamId {
                // Close this window!
                DispatchQueue.main.async {
                    videoStreamVC.window?.close()
                }
                
                if let index = MeetingState.shared.videoWindows.firstIndex(of: videoStreamVC)
                {
                    MeetingState.shared.videoWindows.remove(at: index)
                }
            }
        }
    }
}
