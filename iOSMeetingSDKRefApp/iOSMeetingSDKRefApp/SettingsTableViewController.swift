//
//  SettingsTableViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/29/21.
//

import UIKit
import MeetingSDK_iOS

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {

    // We use statically defined table view cells for the Settings Table View,
    // so all needed outlets from various cells are defined/connected here
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    @IBOutlet weak var audioInputLabel: UILabel!
    @IBOutlet weak var audioOutputLabel: UILabel!
    
    @IBOutlet weak var joinMeetingButton: UIButton!
    @IBOutlet weak var inputLevelSlider: UISlider!
    @IBOutlet weak var outputLevelSlider: UISlider!
    
    // A few enums to make our lives a little easier and code a little more readable
    enum SettingsSections: Int {
        case connectionInfo = 0
        case audioVideoInfo = 1
        case meetingControls = 2
    }
    
    enum AudioVideoItems: Int {
        case audioInputDevice = 0
        case audioOutputDevice = 1
        case videoDevices = 2
    }
    
    // The standard viewDidLoad method for our Settings Table View
    override func viewDidLoad() {
        super.viewDidLoad()

        // This class will serve as the TextFieldDelegate for most of the text fields
        serverTextField.delegate = self
        uuidTextField.delegate = self
        userNameTextField.delegate = self
        
        tableView.keyboardDismissMode = .onDrag
        
        // We need to set some observers (NSNotification) for when notifications are sent from
        // elsewhere inthe application
        NotificationCenter.default.addObserver(self, selector: #selector(meetingExited(notification:)), name: NSNotification.Name(rawValue: "meetingExited"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableLocalVideo(notification:)), name: NSNotification.Name(rawValue: "enableLocalVideo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disableLocalVideo(notification:)), name: NSNotification.Name(rawValue: "disableLocalVideo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flipDeviceCamera(notification:)), name: NSNotification.Name(rawValue: "flipDeviceCamera"), object: nil)

        // By default, input and output levels are set to 50.   Keep in mind that as of the
        // original implementation of this reference app, it is not possible to set the value
        // of the input level or the overall output level on iOS.   This is dependent upon the
        // WebRTC library linked deep in the SDK and may change in the future (which is why we
        // still have the interface for setting these levels present)
        inputLevelSlider.value = 50.0
        outputLevelSlider.value = 50.0
    }

    // A routine to look at the outgoing video options in the MeetingState object and enable them.
    func enableOutgoingAudioVideo() {
        // First enable audio input
        if let audioInput = MeetingState.shared.audioInputDeviceName {
            if audioInput != "None" {
                // We've got a real audio input device, use it!
                MeetingSDK.shared.enableAudioInput(device: audioInput)
            }
        }
        
        // Next enable audio output
        if let audioOutput = MeetingState.shared.audioOutputDeviceName {
            if audioOutput != "None" {
                MeetingSDK.shared.enableAudioOutput(device: audioOutput)
            }
        }
        
        // Enable video devices.   This must be done as a series of chained
        // asyncrhronous calls otherwise it doesn't work properly
        enableNextVideoDevice(devices: MeetingState.shared.videoDevicesUsed)
    }
    
    private func enableNextVideoDevice(devices: [String: String]?) {
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
                        
                        // We're going to reference the "lastError" variable from the lower level SDK
                        // At some point this will be accessible from the higher level API
                        print(text)
                        print("Error: \(MeetingAPI.sharedInstance().lastError)")
                    }
                }
            }
        }
    }
    

    // NSNotification observer used to enable all video devices
    @objc func enableLocalVideo(notification: NSNotification) {
        enableNextVideoDevice(devices: MeetingState.shared.videoDevicesUsed)
    }

    // NSNotification observer used just to set the exit meeting button back
    // to "Join Meeting" if we exit from the video views hang up button.
    @objc func disableLocalVideo(notification: NSNotification) {
        for (device, _) in MeetingState.shared.videoDevicesUsed {
            MeetingSDK.shared.disableVideoCapture(camera: device)
        }

    }

    // NSNotification observer used just to set the exit meeting button back
    // to "Join Meeting" if we exit from the video views hang up button.
    @objc func meetingExited(notification: NSNotification) {
        // Clean up local model objects
        joinMeetingButton.setTitle("Join Meeting", for: .normal)
    }
    
    
    // NSNotification observer used to take action if the user taps the "flip camera" button
    @objc func flipDeviceCamera(notification: NSNotification) {
        // All we do here is cycle through the videoDevicesUsed and if we find "Front" in the device name we disable it
        // and enable "Back Camera" and vice versa.
        for (device, codec) in MeetingState.shared.videoDevicesUsed {
            if device.contains("Front") {
                MeetingSDK.shared.disableVideoCapture(camera: device)
                MeetingState.shared.videoDevicesUsed.removeValue(forKey: device)
                let supportedCodecs = MeetingSDK.shared.getSupportedVideoSendResolutions(deviceId: "Back Camera")
                var useCodec:String? = nil
                
                if supportedCodecs.contains(codec) {
                    useCodec = codec
                } else {
                    useCodec = supportedCodecs.first
                }
                
                if let useCodec = useCodec {
                    MeetingSDK.shared.enableVideoCapture(camera: "Back Camera", withMode: useCodec) { success in
                        print("flip to back camera success: \(success)")
                    }
                    
                    MeetingState.shared.videoDevicesUsed["Back Camera"] = useCodec
                }
            } else if device.contains("Back") {
                MeetingSDK.shared.disableVideoCapture(camera: device)
                MeetingState.shared.videoDevicesUsed.removeValue(forKey: device)
                let supportedCodecs = MeetingSDK.shared.getSupportedVideoSendResolutions(deviceId: "Front Camera")
                var useCodec:String? = nil
                
                if supportedCodecs.contains(codec) {
                    useCodec = codec
                } else {
                    useCodec = supportedCodecs.first
                }
                
                if let useCodec = useCodec {
                    MeetingSDK.shared.enableVideoCapture(camera: "Front Camera", withMode: useCodec) { success in
                        print("flip to front camera success: \(success)")
                    }
                    
                    MeetingState.shared.videoDevicesUsed["Front Camera"] = useCodec
                }
            }
        }
    }

    
    // This action also used for "Exit Meeting"
    @IBAction func doJoinMeeting(_ sender: Any) {
        let button = sender as! UIButton
        
        // If we're currently in a meeting, the button's title will be "Exit Meeting"
        // If this is the case, call exitMeeting() and return
        if button.currentTitle == "Exit Meeting" {
            MeetingSDK.shared.exitMeeting()
            NotificationCenter.default.post(name: NSNotification.Name("meetingExited"), object: nil)
            
            DispatchQueue.main.async {
                button.setTitle("Join Meeting", for: .normal)
            }
            
            return
        }
        
        // Begin the process of joining the meeting.  validate that we have the necessary parameters set
        guard let serverName = serverTextField.text else {
            print("serverName must be provided in order to join a meeting")
            return
        }
        
        guard let meetingUUID = uuidTextField.text else {
            print("meetingUUID must be provided in order to join a meeting")
            return
        }
        
        // Simple check to make sure we have the information we need.   If either serverName or
        // meetingUUID are empty, don't continue
        if serverName.count == 0 || meetingUUID.count == 0 || userNameTextField?.text?.count == 0 {
            print("Please make sure server, Meeting UUID, and user name are provided")
            return
        }
        
        // Simple check to make sure that we have an audio input and output device specified in Settings
        if MeetingState.shared.audioInputDeviceName == nil || MeetingState.shared.audioOutputDeviceName == nil {
            print("Please make sure both an audio input and output device are specified in Settings")
            return
        }
        
        // First, we need to initialize the meeting
        MeetingSDK.shared.initializeMeeting(meetingUUID: meetingUUID, server: serverName) { (success) in
            if !success {
                // There was a problem initializing the meeting
                let lastError = MeetingAPI.sharedInstance().lastError
                print("Initialize Meeting Failure, last error: \(lastError)")
                DispatchQueue.main.async {
                    print("Meeting Initializaion Failure: \(lastError)")
                }
            } else {
                //  Proceed with joining the meeting.
                
                // First, move to the VideoGalleryView to make sure delegate is set in time
                DispatchQueue.main.async {
                    button.setTitle("Exit Meeting", for: .normal)
                    self.tabBarController?.selectedIndex = 2
                }
                
                // Then, proceed with the joinMeeting call
                DispatchQueue.main.async {
                    MeetingSDK.shared.joinMeeting(name: (self.userNameTextField?.text)!) { (success) in
                        if success {
                            print("join command succeeded, enabling local audio/video")
                            
                            // Since our application might need to share the screen, we have to initialize
                            // the iOS screen sharing parameters
                            MeetingAPI.sharedInstance().initializeScreenCaptureExtension("com.visionable.iOSMeetingSDKRefApp.ScreenShareExtension", withAppGroup: "group.com.visionable.sdk.screensharing")
                            self.enableOutgoingAudioVideo()
                            MeetingState.shared.meetingIsActive = true
                        } else {
                            print("join command failed: \(MeetingAPI.sharedInstance().lastError)")
                        }
                    }
                }
            }
        }
    }
    
    // If the inputLevel slider is changed this will be called.   Again, we'll make the right MeetingSDK call
    // to respond, but right now it will do nothing
    @IBAction func inputLevelSliderChanged(_ sender: Any) {
        let slider = sender as? UISlider
        if let volume = slider?.value {
            print("setting input level to \(volume)")
            MeetingSDK.shared.setAudioInputVolume(Int32(volume))
        }
    }
    
    // If the outputLevel slider is changed this will be called.   Again, we'll make the right MeetingSDK call
    // to respond, but right now it will do nothing
    @IBAction func outputLevelSliderChanged(_ sender: Any) {
        let slider = sender as? UISlider
        if let volume = slider?.value {
            print("setting output level to \(volume)")
            MeetingSDK.shared.setAudioOutputVolume(Int32(volume))
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // MARK: --
    // MARK: Table View Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SettingsSections.audioVideoInfo.rawValue {
            // We're in the Audio/Video section, look for either audio input or output device
    
            if indexPath.row == AudioVideoItems.audioInputDevice.rawValue {
                // Display action sheet for audio input devices
                var audioInputDevices = MeetingSDK.shared.getAudioInputDevices()
                audioInputDevices.append("None")
                let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
                
                for audioDevice in audioInputDevices {
                    let action = UIAlertAction(title: audioDevice, style: .default) { (alertAction) in
                        // TO-DO: Store in model object
                        DispatchQueue.main.async {
                            if audioDevice == "None" {
                                MeetingState.shared.audioInputDeviceName = nil
                                self.audioInputLabel.text = "No device selected"
                            } else {
                                MeetingState.shared.audioInputDeviceName = audioDevice
                                self.audioInputLabel.text = audioDevice
                            }
                        }
                    }
                    
                    optionMenu.addAction(action)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(cancelAction)
                
                // Set popover location info in case we're on an iPad
                if let selectedCell = tableView.cellForRow(at: indexPath) {
                    optionMenu.popoverPresentationController?.sourceView = selectedCell
                    optionMenu.popoverPresentationController?.sourceRect = selectedCell.bounds
                }
                self.present(optionMenu, animated: true, completion: nil)
            } else if indexPath.row == AudioVideoItems.audioOutputDevice.rawValue {
                let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
                
                var audioOutputDevices = MeetingSDK.shared.getAudioOutputDevices()
                audioOutputDevices.append("None")
                
                for audioDevice in audioOutputDevices {
                    let action = UIAlertAction(title: audioDevice, style: .default) { (alertAction) in
                        // TO-DO: Store in model object
                        DispatchQueue.main.async {
                            if audioDevice == "None" {
                                MeetingState.shared.audioOutputDeviceName = nil
                                self.audioOutputLabel.text = "No device selected"
                            } else {
                                MeetingState.shared.audioOutputDeviceName = audioDevice
                                self.audioOutputLabel.text = audioDevice
                            }
                        }
                    }
                    
                    optionMenu.addAction(action)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(cancelAction)
                
                // Set popover location info in case we're on an iPad
                if let selectedCell = tableView.cellForRow(at: indexPath) {
                    optionMenu.popoverPresentationController?.sourceView = selectedCell
                    optionMenu.popoverPresentationController?.sourceRect = selectedCell.bounds
                }

                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
}
