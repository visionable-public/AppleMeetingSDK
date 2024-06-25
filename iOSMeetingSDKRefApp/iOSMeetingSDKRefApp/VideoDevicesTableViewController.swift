//
//  VideoDevicesTableViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 5/1/21.
//

import UIKit
import MeetingSDK_iOS

class VideoDevicesTableViewController: UITableViewController, MeetingSDKDelegate {
    var previewView: VideoView? = nil
    var subviewAdded: VideoView? = nil
    
    func participantRemoved(participant: MeetingSDK_iOS.Participant) {
        
    }
    
    func previewVideoViewCreated(videoView: VideoView) {
        print("PREVIEW: previewVideoViewCreated!")
        previewView = videoView
        previewView?.backgroundColor = .white
        previewView?.frame.size = CGSize(width: 500, height: 250)
        self.tableView.reloadData()
    }
    
    func logMessage(level: Int, message: String) {
        print("(\(level)) -- \(message)")
    }
    
    var devices: [String] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "VideoDeviceCell")
        //self.tableView.register(VideoDevicePreviewCell.self, forCellReuseIdentifier: "VideoDevicePreviewCell")
        devices = MeetingSDK.shared.getVideoDevices()
        MeetingSDK.shared.delegate = self
        MeetingSDK.shared.enableCombinedLogs(false)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (section == 0) {
            return devices.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Available Devices"
        } else {
            return "Preview"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoDeviceCell", for: indexPath)
            let device  = devices[indexPath.row]
            
            // Configure the cell...
            cell.textLabel?.text = devices[indexPath.row]
            
            if let codec = MeetingState.shared.videoDevicesUsed[device] {
                cell.detailTextLabel?.text = codec
            } else {
                cell.detailTextLabel?.text = "Not enabled"
            }
            
            return cell
        } else {
            print("PREVIEW: getting DevicePreviewCell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "VideoDevicePreviewCell", for: indexPath) as! VideoDevicePreviewCell
            if previewView !=  nil && subviewAdded == nil {
                print("PREVIEW: adding previewView as subview of preview cell")
                cell.contentView.addSubview(previewView!)
                subviewAdded = previewView
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 50
        } else {
            return 300
        }
    }
    @IBAction func previewButtonTapped(_ sender: Any) {
        // Preview Button was tapped.   Look for first cell that does not have
        // "Not enabled" as it's codec and start a preview for it
        
        if previewView != nil {
            print("PREVIEW: Stopping preview")
            
            if subviewAdded != nil {
                subviewAdded?.removeFromSuperview()
                subviewAdded = nil
            }
            
            // Already running preview, stop
            for (device, _) in MeetingState.shared.videoDevicesUsed {
                // Just disable first one encountered
                print("PREVIEW:  Disabling preview for \(device)")
                MeetingSDK.shared.disableVideoPreview(camera: device)
                previewView = nil
                self.tableView.reloadData()
                break
            }
            
        } else {
            print("PREVIEW: Looking for device to preview")
            for (device, codec) in MeetingState.shared.videoDevicesUsed {
                print("PREVIEW: starting preview")
                // Just enable first one encountered
                print("PREVIEW: Enabling preview for \(device) with codec: \(codec)")
                MeetingSDK.shared.enableVideoPreview(camera: device, withMode: codec, andBlurring: true, lowLevel:false) { success in
                    print("PREVIEW: enableVideoPreview returned \(success)")
                }
                break
            }
        }
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        self.tableView.deselectRow(at: indexPath, animated: true)
        var codecs = MeetingSDK.shared.getSupportedVideoSendResolutions(deviceId: device)
        
        let codecMenu = UIAlertController(title: nil, message: "Choose a Resolution", preferredStyle: .actionSheet)
        
        codecs.append("Not enabled")
        
        for codec in codecs {
            let action = UIAlertAction(title: codec, style: .default) { (alertAction) in
                DispatchQueue.main.async {
                    if codec == "Not enabled" {
                        MeetingState.shared.videoDevicesUsed.removeValue(forKey: device)
                        if MeetingState.shared.meetingIsActive {
                            MeetingSDK.shared.disableVideoCapture(camera: device)
                        }
                    } else {
                        MeetingState.shared.videoDevicesUsed[device] = codec
                        if MeetingState.shared.meetingIsActive {
                            MeetingSDK.shared.enableVideoCapture(camera: device, withMode: codec) { success in
                                if success {
                                    print("Meeting is live, enabled video capture for \(device) with codec \(codec)")
                                }
                            }
                        }
                        
                        // Pop back to settings
                        //self.navigationController?.popViewController(animated: true) /// Added by Nick, then revoked
                    }
                    self.tableView.reloadData()
                }
            }
            
            codecMenu.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        codecMenu.addAction(cancelAction)
        
        // Set popover location info in case we're on an iPad
        if let selectedCell = tableView.cellForRow(at: indexPath) {
            codecMenu.popoverPresentationController?.sourceView = selectedCell
            codecMenu.popoverPresentationController?.sourceRect = selectedCell.bounds
        }

        self.present(codecMenu, animated: true, completion: nil)
    }
}
