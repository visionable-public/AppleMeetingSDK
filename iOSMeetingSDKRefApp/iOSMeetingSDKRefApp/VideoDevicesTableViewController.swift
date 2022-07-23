//
//  VideoDevicesTableViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 5/1/21.
//

import UIKit
import MeetingSDK_iOS

class VideoDevicesTableViewController: UITableViewController {

    var devices: [String] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "VideoDeviceCell")
        devices = MeetingSDK.shared.getVideoDevices()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return devices.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
