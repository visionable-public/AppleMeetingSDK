//
//  VideoInfoViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Aaron Treinish on 5/12/21.
//

import UIKit
import MeetingSDK_iOS

// Manages the table view that shows video info
class VideoInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var videoInfoTableView: UITableView!
    
    var participant: Participant?
    var videoInfo: [VideoInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoInfoTableView.delegate = self
        videoInfoTableView.dataSource = self
    }
    
    // MARK: - UITableViewDelegate and UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "videoInfoCell", for: indexPath) as? VideoInfoTableViewCell else { return UITableViewCell() }
        
        let videoInfo = videoInfo[indexPath.row]
        
        cell.streamIdLabel.text = "Stream ID: " + videoInfo.streamId
        cell.siteLabel.text = "Site: " + videoInfo.site
        cell.deviceNameLabel.text = "Device Name: " + videoInfo.name
        cell.activeLabel.text = "Active: " + videoInfo.active
        cell.codecNameLabel.text = "Codec Name: " + videoInfo.codecName
        cell.localLabel.text = "Local: " + videoInfo.local
        cell.layoutLabel.text = "Layout: " + videoInfo.local
        cell.widthLabel.text = "Width: " + videoInfo.width
        cell.heightLabel.text = "Height: " + videoInfo.height
        
        print("iOSReferenceApp:VideoInfoViewController -- cellForRowAt -- videoInfo.streamId: \(videoInfo.streamId), active flag is \(videoInfo.active)")
        if videoInfo.active == "true" {
            cell.enableDisableVideoStreamButton.setTitle("Disable Video Stream", for: .normal)
        } else {
            cell.enableDisableVideoStreamButton.setTitle("Enable Video Stream", for: .normal)
        }
        
        cell.enableDisableVideoStreamButton.tag = indexPath.row
        cell.enableDisableVideoStreamButton.addTarget(self, action: #selector(enableDisableVideoStream(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func enableDisableVideoStream(_ sender: UIButton) {
        let buttonTag = sender.tag
        let videoInfo = videoInfo[buttonTag]
        
        if videoInfo.active == "true" {
            disableVideoStream(streamId: videoInfo.streamId)

            NotificationCenter.default.post(name: NSNotification.Name("videoStreamDisabled"), object: videoInfo.videoView)
        } else {
            enableVideoStream(streamId: videoInfo.streamId)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func enableVideoStream(streamId: String) {
        if let participant = participant {
            MeetingSDK.shared.enableVideoStream(participant: participant, streamId: streamId)
            DispatchQueue.main.async {
                self.videoInfoTableView.reloadData()
            }
        }
    }
    
    func disableVideoStream(streamId: String) {
        MeetingSDK.shared.disableVideoStream(streamId: streamId)
        DispatchQueue.main.async {
            self.videoInfoTableView.reloadData()
        }
    }

}
