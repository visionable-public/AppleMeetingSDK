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
    
    @IBOutlet weak var useV3Switch: UISwitch!
    @IBOutlet weak var joinMeetingButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
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
    
    enum UserDefaultKeys: String {
        case serverTextField = "serverTextField"
        case uuidTextField = "uuidTextField"
        case userNameTextField = "userNameTextField"
    }
    
    // The standard viewDidLoad method for our Settings Table View
    override func viewDidLoad() {
        super.viewDidLoad()

        // This class will serve as the TextFieldDelegate for most of the text fields
        serverTextField.delegate = self
        uuidTextField.delegate = self
        userNameTextField.delegate = self
        
        // Fill in text field's with previous values
        let defaults = UserDefaults.standard
        serverTextField.text = defaults.string(forKey: UserDefaultKeys.serverTextField.rawValue)
        uuidTextField.text = defaults.string(forKey: UserDefaultKeys.uuidTextField.rawValue)
        userNameTextField.text = defaults.string(forKey: UserDefaultKeys.userNameTextField.rawValue)
        
        tableView.keyboardDismissMode = .onDrag
        
        // We need to set some observers (NSNotification) for when notifications are sent from
        // elsewhere inthe application
        NotificationCenter.default.addObserver(self, selector: #selector(meetingExited(notification:)), name: NSNotification.Name(rawValue: "meetingExited"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableLocalVideo(notification:)), name: NSNotification.Name(rawValue: "enableLocalVideo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disableLocalVideo(notification:)), name: NSNotification.Name(rawValue: "disableLocalVideo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flipDeviceCamera(notification:)), name: NSNotification.Name(rawValue: "flipDeviceCamera"), object: nil)
        
        // Round the corners of the joinMeetingButton. This isn't a Windows 8 app.
        joinMeetingButton.layer.cornerRadius = joinMeetingButton.frame.height/2

        // By default, input and output levels are set to 50.   Keep in mind that as of the
        // original implementation of this reference app, it is not possible to set the value
        // of the input level or the overall output level on iOS.   This is dependent upon the
        // WebRTC library linked deep in the SDK and may change in the future (which is why we
        // still have the interface for setting these levels present)
        inputLevelSlider.value = 50.0
        outputLevelSlider.value = 50.0
    }
    
    
    // Assigns the input and output audio devices to the default devices, return true if succesfully set the requested devices
    func setAudioDevicesToDefault(input: Bool, output: Bool) -> Bool {
        
        // Set default input device
        if input {
            var audioInputDevices = MeetingSDK.shared.getAudioInputDevices()
            guard let defaultDevice = audioInputDevices.first else {
                print("No default audio input device!")
                return false
            }
            
            MeetingState.shared.audioInputDeviceName = defaultDevice
            self.audioInputLabel.text = defaultDevice
            self.audioInputLabel.textColor = .none
        }
        
        // Set default output device
        if output {
            var audioOutputDevices = MeetingSDK.shared.getAudioOutputDevices()
            guard let defaultDevice = audioOutputDevices.first else {
                print("No default audio input device!")
                return false
            }
            
            MeetingState.shared.audioOutputDeviceName = defaultDevice
            self.audioOutputLabel.text = defaultDevice
            self.audioOutputLabel.textColor = .none
        }
        
        return true
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

    
    @IBAction func doJoinMeeting(_ sender: Any) {
        
        let joinV3 = useV3Switch.isOn
        
        if joinV3 {
            doJoinMeetingV3(sender)
        }
        else {
            doJoinMeetingV2(sender)
        }
        
    }
    
    
    func doJoinMeetingV3(_ sender: Any) {
        let button = sender as! UIButton
        
        // If we're currently in a meeting, the button's title will be "Exit Meeting"
        // If this is the case, call exitMeeting() and return
        if button.currentTitle == "Exit Meeting" {
            MeetingSDK.shared.exitMeeting()
            NotificationCenter.default.post(name: NSNotification.Name("meetingExited"), object: nil)
            
            DispatchQueue.main.async {
                button.setTitle("Join Meeting V3", for: .normal)
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
            
            // Make text red so user knows what they forgot
            if MeetingState.shared.audioInputDeviceName == nil {
                audioInputLabel.textColor = .red
            }
            if MeetingState.shared.audioOutputDeviceName == nil {
                audioOutputLabel.textColor = .red
            }
            
            // Alert user that their audio devices weren't set, and give option to use defeult devices
            let alert = UIAlertController(title: "Devices Not Set", message: "You must select audio input & output devices to join a meeting. Would you like to set these to the default device?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { [self] _ in
                setAudioDevicesToDefault(input: MeetingState.shared.audioInputDeviceName == nil, output: MeetingState.shared.audioOutputDeviceName == nil)
                doJoinMeetingV3(sender)
            })
            alert.addAction(UIAlertAction(title: "No", style: .default))
            self.present(alert, animated: true)
            
            return
        }
        
        let token = "eyJraWQiOiJaZVJMOFc3U0t5SGkzSXYxUkJqblFIUkRRc1BXWjF0M3pVdWhQTDNjclcwPSIsImFsZyI6IlJTMjU2In0.eyJmZWF0dXJlX2lkIjoiMjM5ZTU4ZGEtOTdjOS00MDI0LWFkMGItODVmMTI0NDE1Yjg3IiwiZmVhdHVyZV9zaGFyZV9oaWdoIjoidHJ1ZSIsImZlYXR1cmVfc2hhcmVfbWVkaXVtIjoiZmFsc2UiLCJ1c2VyX2xhc3RuYW1lIjoiRGlOYXBvbGkiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9FU1lQdkdoTjMiLCJmZWF0dXJlX3ZpZGVvXzEwODBwIjoiZmFsc2UiLCJmZWF0dXJlX2NoYXQiOiJ0cnVlIiwiZmVhdHVyZV92aWV3cyI6IjEwMDAiLCJzdWJzY3JpcHRpb25faWQiOiI3ZmZmMmE1My1hMzc5LTRkNjQtOTBlOS1lZjNkZWM2Zjk2MzciLCJmZWF0dXJlX2hhbmQiOiJmYWxzZSIsImF1dGhfdGltZSI6MTY1NzE5NTQyNSwiZXhwIjoxNjU3MTk5MDI1LCJmZWF0dXJlX3NpcCI6ImZhbHNlIiwiZmVhdHVyZV9wdHoiOiJ0cnVlIiwiZmVhdHVyZV9uYW1lIjoiUFJPIiwidXNlcl9maXJzdG5hbWUiOiJSb24iLCJmZWF0dXJlX3JlY29yZF9yZW1vdGUiOiJ0cnVlIiwiZmVhdHVyZV9maWxlIjoidHJ1ZSIsImNvZ25pdG86dXNlcm5hbWUiOiJmNTZiYWRjNC01ZTY4LTQ2ZjgtODI4ZS0wNzk2YTBhOTYyYTkiLCJmZWF0dXJlX3NoYXJlcyI6IjEwMDAiLCJmZWF0dXJlX2d1ZXN0cyI6IjEwMDAiLCJhdWQiOiI1YWkyZmVlazFyZ3BzbzQ5N29tMWtiajR1ZyIsImZlYXR1cmVfdmlkZW9fbG9zc2xlc3MiOiJ0cnVlIiwidG9rZW5fdXNlIjoiaWQiLCJmZWF0dXJlX3NpemUiOiIxMDAwIiwiZmVhdHVyZV9jYW1lcmFzIjoiMTAwMCIsImZlYXR1cmVfdmlkZW9fOTYwcCI6InRydWUiLCJmZWF0dXJlX3ZpZGVvX2NpZiI6InRydWUiLCJzdWIiOiJmNTZiYWRjNC01ZTY4LTQ2ZjgtODI4ZS0wNzk2YTBhOTYyYTkiLCJmZWF0dXJlX3NoYXJlX2Jlc3QiOiJ0cnVlIiwiZmVhdHVyZV92aWRlb19xY2lmIjoidHJ1ZSIsImZlYXR1cmVfdmlkZW9fdmdhIjoidHJ1ZSIsImZlYXR1cmVfcGl4IjoidHJ1ZSIsImlhdCI6MTY1NzE5NTQyNSwianRpIjoiZjZhZTcxN2MtOWQwZC00MjUwLThkNjMtZjFjYzVlMzcyZGYyIiwiZW1haWwiOiJyZGluYXBvbGlAdmlzaW9uYWJsZS5jb20iLCJ1c2VyX2Rpc3BsYXluYW1lIjoiUm9uIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZlYXR1cmVfc2hhcmVfbG93IjoiZmFsc2UiLCJiaWxsaW5nX2lkIjoiNTcxZmQyMWYtNGQyZC00MGQ2LTkxMGQtODMyNmEzZTRiYTFkIiwiYXNzaWdubWVudF9pZCI6IjYzMThhNTFkLWIxYTQtNDg2Ny05MDJmLTk3YzRjYmUxMjA5NSIsIm9yaWdpbl9qdGkiOiI3ZjM2YmEyMC1mZDhjLTQwNTYtOWYxZi1mZTBiY2ZmMzU2YTkiLCJhY2NvdW50X2lkIjoiNGIxZTNmN2YtMDc4Yi00NzdkLThjNDYtODkzODMwOWM2YmIxIiwiZXZlbnRfaWQiOiI2ZmQxMjBhOC02MTIxLTQ5ZmMtYjE3Zi00MTJjODI4NjA0YzMiLCJmZWF0dXJlX3JlY29yZF9sb2NhbCI6InRydWUiLCJmZWF0dXJlX3BzdG4iOiJ0cnVlIiwiZmVhdHVyZV9oMzIzIjoidHJ1ZSIsImZlYXR1cmVfdmlkZW9fNzIwcCI6InRydWUifQ.ba7g-pgFhbk9ggUz0dMM6T0HzGqr_FwbpAG7rlJnkfTnoRYq-iv7MttRkiwWu0LdCTfqWwZIB7lvxBzqVOz-iJejKhYb7BdTFr3J56_F_OyizjyqsRzpQL1y4Uxfqvu2mbk8IEju7pdO2WuxUKZ6sEA3rFjesySl4S_FVIQQrvjdjwxGcMpFvG8-dnyOV6-xDBMI3W2o4CHkHOTOkmjdexoeRmMfCRROsN0OZhqLx0pl8Rm8mgDPFmKvgrhGbsM7d7_M9jnj4Z5Hgw_PCwmssVGWl7i3iT2it5kU90zvInm5R7HIXT7mzkzc2GaMx9VYSHFl9y1vs3x7AAlj2I52pQ"
        
        joinMeetingButton.isHidden = true
        activityIndicator.startAnimating()
        
        // First, we need to initialize the meeting
        MeetingSDK.shared.initializeMeetingWithToken(meetingUUID: meetingUUID, server: serverName, token: nil) { (success, mjwt) in
            
            DispatchQueue.main.async {
                self.joinMeetingButton.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            
            if !success {
                // There was a problem initializing the meeting
                let lastError = MeetingAPI.sharedInstance().lastError
                print("Initialize Meeting Failure, last error: \(lastError)")
                DispatchQueue.main.async {
                    print("Meeting Initializaion Failure: \(lastError)")
                    
                    // Alert the user of the error
                    let alert = UIAlertController(title: "Meeting Initializaion Failure", message: lastError, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .default))
                    self.present(alert, animated: true)
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
                    MeetingSDK.shared.joinMeetingWithToken(server: serverName, meetingUUID: meetingUUID, token: mjwt, userUUID: "", name: (self.userNameTextField?.text)!) { (success) in
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
    
    
    // This action also used for "Exit Meeting"
    func doJoinMeetingV2(_ sender: Any) {
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
            
            // Make text red so user knows what they forgot
            if MeetingState.shared.audioInputDeviceName == nil {
                audioInputLabel.textColor = .red
            }
            if MeetingState.shared.audioOutputDeviceName == nil {
                audioOutputLabel.textColor = .red
            }
            
            // Alert user that their audio devices weren't set, and give option to use defeult devices
            let alert = UIAlertController(title: "Devices Not Set", message: "You must select audio input & output devices to join a meeting. Would you like to set these to the default device?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { [self] _ in
                setAudioDevicesToDefault(input: MeetingState.shared.audioInputDeviceName == nil, output: MeetingState.shared.audioOutputDeviceName == nil)
                doJoinMeetingV2(sender)
            })
            alert.addAction(UIAlertAction(title: "No", style: .default))
            self.present(alert, animated: true)
            
            return
        }
        
        joinMeetingButton.isHidden = true
        activityIndicator.startAnimating()
        
        // First, we need to initialize the meeting
        MeetingSDK.shared.initializeMeeting(meetingUUID: meetingUUID, server: serverName) { (success, key) in
            
            DispatchQueue.main.async {
                self.joinMeetingButton.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            
            if !success {
                // There was a problem initializing the meeting
                let lastError = MeetingAPI.sharedInstance().lastError
                print("Initialize Meeting Failure, last error: \(lastError)")
                DispatchQueue.main.async {
                    print("Meeting Initializaion Failure: \(lastError)")
                    
                    // Alert the user of the error
                    let alert = UIAlertController(title: "Meeting Initializaion Failure", message: lastError, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .default))
                    self.present(alert, animated: true)
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
                    MeetingSDK.shared.joinMeeting(server: serverName, meetingUUID: meetingUUID, key: key, userUUID: "", name: (self.userNameTextField?.text)!) { (success) in
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // Save the user-entered value so it can persist the next time the app is opened
        let key: String!
        
        switch textField {
        case serverTextField:
            key = UserDefaultKeys.serverTextField.rawValue
        case uuidTextField:
            key = UserDefaultKeys.uuidTextField.rawValue
        case userNameTextField:
            key = UserDefaultKeys.userNameTextField.rawValue
        default:
            return
        }
        
        let defaults = UserDefaults.standard
        defaults.set(textField.text, forKey: key)
    }
    
    /// MARK: --
    // MARK: - Table View Delegate Methods
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
                                self.audioInputLabel.textColor = .none
                            }
                        }
                    }
                    
                    optionMenu.addAction(action)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(cancelAction)
                
                if let selectedCell = tableView.cellForRow(at: indexPath) {
                    // Set popover location info in case we're on an iPad
                    optionMenu.popoverPresentationController?.sourceView = selectedCell
                    optionMenu.popoverPresentationController?.sourceRect = selectedCell.bounds
                    
                    // Deselect so the cell doesn't remain selected
                    selectedCell.setSelected(false, animated: true)
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
                                self.audioOutputLabel.textColor = .none
                            }
                        }
                    }
                    
                    optionMenu.addAction(action)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(cancelAction)
                
                if let selectedCell = tableView.cellForRow(at: indexPath) {
                    // Set popover location info in case we're on an iPad
                    optionMenu.popoverPresentationController?.sourceView = selectedCell
                    optionMenu.popoverPresentationController?.sourceRect = selectedCell.bounds
                    
                    // Deselect so the cell doesn't remain selected
                    selectedCell.setSelected(false, animated: true)
                }

                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
}
