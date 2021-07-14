//
//  ParticipantsViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Aaron Treinish on 5/12/21.
//

import UIKit
import MeetingSDK_iOS

// The ParticipantsView object is the main view object that is added to the "Videos" view controller.
// One such view is created for each camera feed in the meeting.   The user will be able to move
// these views around with tap/drag, and then can pinch/zoom to make bigger/smaller

class ParticipantsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var audioStreams: [String: Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate and UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeetingSDK.shared.participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "participantsCell", for: indexPath) as? ParticipantsTableViewCell else { return UITableViewCell() }
        
        let participant = MeetingSDK.shared.participants[indexPath.row]
        
        cell.userUUIDLabel.text = "User UUID: " + participant.userUUID
        cell.audioInfoStreamIdLabel.text = "Stream ID: " + (participant.audioInfo?.streamId ?? "")
        cell.audioInfoSiteLabel.text = "Site: " + (participant.audioInfo?.site ?? "")
        
        // Make sure we have audioInfo for this participant (should be for most remote participants
        // but not for the local participant)
        if let audioInfo = participant.audioInfo {
            // Check to see if we already know the volume for this stream
            if let audioLevel = self.audioStreams[audioInfo.streamId] {
                    // We do know the volume, set the slider accordingly
                    cell.volumeSlider.value = Float(audioLevel)
            } else {
                    // We don't know the volume leavel, set to the default of 50
                    // and note in the audioStreams dictionary
                    cell.volumeSlider.value = 50
                    audioStreams[audioInfo.streamId] = 50
            }
            
            // Store the Stream ID in the slider's tag field.   Need to convert to an integer first.
            cell.volumeSlider.tag = Int(audioInfo.streamId) ?? 0
            cell.volumeSlider.addTarget(self, action: #selector(sliderValueChanged(sender:event:)), for: .valueChanged)
        }
        else
        {
            cell.volumeSlider.isHidden = true
        }

        cell.seeVideoInfoButton.tag = indexPath.row
        cell.seeVideoInfoButton.addTarget(self, action: #selector(seeInfoVideoButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func sliderValueChanged(sender: UISlider, event: UIEvent) {
        var audioInfo: [AudioInfo] = []
        for participant in MeetingSDK.shared.participants {
            if let info = participant.audioInfo {
                audioInfo.append(info)
            }
        }
        
        // When receiving slider events, wait until we get the last one to set the volume stream
        // This is not absolutely necessary (we could keep calling the APIs to change the stream's
        // volume on every minute change of the slider) but this cuts down on unnecessary intermediate
        // calls to the SDK.
        if let touchEvent = event.allTouches?.first {
            let currentValue = Int(sender.value)
            
            // We've stored the streamId in the slider's tag field.   If we didn't have a stream id
            // this will be 0 which we'll deal with below
            let streamId = String(sender.tag)
            
            switch touchEvent.phase {
            case .ended:
                // Make sure we have a valid stream id
                if sender.tag > 0 {
                    audioStreams[streamId] = currentValue
                    MeetingSDK.shared.setAudioStreamVolume(streamId: streamId, volume: Int32(currentValue))
                }
            default:
                break
            }
        }
    }
    
    // Bring up the Video Info view controller when the appropriate button is tapped
    @objc func seeInfoVideoButtonTapped(_ sender: UIButton){
        let buttonTag = sender.tag
        let participant = MeetingSDK.shared.participants[buttonTag]
        let videoInfo = MeetingSDK.shared.participants[buttonTag].videoInfo
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "VideoInfoViewController") as! VideoInfoViewController
        viewController.videoInfo = videoInfo
        viewController.participant = participant
        viewController.title = "Video Info"
        viewController.navigationItem.largeTitleDisplayMode = .never
        viewController.modalPresentationStyle = .fullScreen
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}
