//
//  VideoGalleryViewController.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 6/30/21.
//

import UIKit
import MeetingSDK_iOS


// This extension returns a CGRect that corresponds to the size of the image (scaled with
// .aspectFit).   We'll use this to properly size the Participant view after image scale so there
// are not vertical or horizontal white bars shown
extension UIImageView {
    var scaledImageRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

// Manages the "Videos" view controller which will allow the user to drag and resize
// a number of ParticipantView objects on a 5000x5000 scroll view
class VideoGalleryViewController: UIViewController, MeetingSDKDelegate {

    enum VideoOnOffState {
        case on
        case off
    }
    
    enum MicOnOffState {
        case on
        case off
    }
    
    // Keep track of state associated with the control buttons that are overlaid
    // at the bottom of the scroll view
    private var micOnOffState: MicOnOffState = .on
    private var videoOnOffState: VideoOnOffState = .on

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var meetingControlView: UIView!
    
    // Outlets for the buttons at the bottom of the scroll view
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var endCallButton: UIButton!

    // Keep track of ParticipantViews
    var participantViews:[ParticipantView] = []
    
    // We use a zIndex integer that is constantly incremented and assigned to the view we want on top.
    // For a real app, we'd need to handle the case where this value eventually overflows the size of
    // the data type associated with it, but for a reference app, it's fine
    var zIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting the delegate of the MeetingSDK
        MeetingSDK.shared.delegate = self
        
        // Set the scroll view content size to 5000x5000 and enable scrolling
        self.scrollView.contentSize = CGSize(width: 5000.0, height: 5000.0)
        self.scrollView.isScrollEnabled = true
        
        // Add observers for when video streams are disabled and when the meeting exits
        NotificationCenter.default.addObserver(self, selector: #selector(videoStreamDisabled(notification:)), name: NSNotification.Name(rawValue: "videoStreamDisabled"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(meetingExited(notification:)), name: NSNotification.Name(rawValue: "meetingExited"), object: nil)
        
        // Set the view containing the control buttons at the topmost value for zIndex so it is always on top
        meetingControlView.layer.zPosition = CGFloat(INT32_MAX)
    }
    
    // The selector called when a videoStreamDisabled NSNotification is received.   We'll
    // get the associated VideoView as the notification object;  we just need to map it to
    // the appropriate ParticipantView and then remove that participant view from our array
    // of objects and from the view hierarchy
    @objc func videoStreamDisabled(notification: NSNotification) {
        guard let videoView = notification.object as? VideoView else { return }
        
        for (index, view) in participantViews.enumerated() {
            if view.videoView == videoView {
                participantViews.remove(at: index)
                DispatchQueue.main.async {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    // The selector called when a meetingExited NSNotification is received.  We'll
    // iterate through all the participant views and remove them from the array of
    // objects as well as remove them from the view hierarchy
    @objc func meetingExited(notification: NSNotification) {
        // Clean up local model objects
        participantViews.forEach { $0.removeFromSuperview() }
        participantViews.removeAll()
        MeetingState.shared.meetingIsActive = false
    }
    
    
    // Called when the user taps on the "Video" control button.    This will cause our local
    // video to be disabled by sending a disableLocalVideo NSNotification (picked up elsewhere and
    // acted upon).   If the local video was already disabled, this will re-enable it.
    @IBAction func videoButtonAction(_ sender: Any) {
        // Turns all video sources on and off
        if videoOnOffState == .on {
            videoOnOffState = .off
            videoButton.setImage(UIImage(systemName: "video.slash.fill"), for: .normal)
            NotificationCenter.default.post(name: NSNotification.Name("disableLocalVideo"), object: nil)
        } else {
            videoOnOffState = .on
            videoButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
            NotificationCenter.default.post(name: NSNotification.Name("enableLocalVideo"), object: nil)
        }
    }
    

    // Called when the user taps on the "Microphone" control button.    This will cause our local
    // audio to be disabled.   If the local audio was already disabled, this will cause the local
    // audio to be re-enabled
    @IBAction func microphoneButtonAction(_ sender: Any) {
        // Handling turning on and off your mic
        if micOnOffState == .on {
            micOnOffState = .off
            MeetingSDK.shared.disableAudioInput(device: "Default device")
            microphoneButton.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
        } else {
            micOnOffState = .on
            MeetingSDK.shared.enableAudioInput(device: "Default device")
            microphoneButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        }
    }
    
    // Called when the user taps on the "Flip Camera" button.    This will cause a flipDeviceCamera
    // NSNotification to be send which will be handled elsewhere in the app (causing the camera used
    // to switch from front to back or back to front)
    @IBAction func flipCameraButtonAction(_ sender: Any) {
        // Handling flipping your camera from front to back
        NotificationCenter.default.post(name: NSNotification.Name("flipDeviceCamera"), object: nil)
    }
    
    // Called when the user taps on the "End Call" button.   This will cause a meetingExited
    // NSNotification to be sent which will be handled elsewhere in the app (causing the meeting
    // to exit)
    @IBAction func endCallButtonAction(_ sender: Any) {
        // Ending the meeting
        MeetingSDK.shared.exitMeeting()
        NotificationCenter.default.post(name: NSNotification.Name("meetingExited"), object: nil)
    }
    
    
    // Gesture recognizers
    // We use the following gesture recognizers to allow manipulation of the Participant Views
    // in the Scrollable Area of the Videos View Controller
    
    // The pan gesture recognizer lets us drag the view around
    @objc func panView(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
     
        if let viewToDrag = sender.view {
            viewToDrag.center = CGPoint(x: viewToDrag.center.x + translation.x,
                y: viewToDrag.center.y + translation.y)
            sender.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
        }
        
        let participantView = sender.view as! ParticipantView
        
        if sender.state == .began {
            // Make sure view is in the foreground
            zIndex = zIndex + 1
            participantView.layer.zPosition = CGFloat(zIndex)
        }

    }

    // The pinchToResize gesture recognizer allows us to (naively) grow and shrink the ParticipantView
    @objc func pinchToResize(_ gesture: UIPinchGestureRecognizer) {
        var identity = CGAffineTransform.identity
        let participantView = gesture.view as? ParticipantView
        
        switch gesture.state {
        case .began:
            identity = participantView!.transform
        case .changed,.ended:
            participantView!.transform = identity.scaledBy(x: gesture.scale, y: gesture.scale)
        case .cancelled:
            break
        default:
            break
        }
    }
    
    
    // MeetingSDKDelegate methods
    // These methods are called by the Meeting SDK engine when certain meeting events occur.
    
    // Depending on the type of user interface you are building, you might use the participantAdded
    // delegate method to trigger an update in your user interface that shows the names of the participants
    // in the meeting.   Our Reference App uses a separate view controller within a Tab Bar controller to show
    // participants.   We've put code to update the table view in that controller on the viewWillAppear method.
    // That works just as well, but if the ParticipantViewController is showing and a new user is added to
    // the meeting, we won't update the list until the next time viewWillAppear is called.   Your application
    // should handle this situation and can utilize participantAdded to do so.
    func participantAdded(participant: Participant) {
        print("iOSReferenceApp::participantAdded")
    }
    
    // Whenever we receive notification that there's a new video stream in the meeting, we immediately
    // enable it so that we'll end up showing the video in our user interface
    func participantVideoAdded(participant: Participant, streamId: String) {
        print("iOSReferenceApp::participantVideoAdded")
        MeetingSDK.shared.enableVideoStream(participant: participant, streamId: streamId)
    }
    
    // We'll get a participantVideoUpdated when something about the specified video stream changes.
    // As long as the stream is still active, we'll remove it and re-add it to pick up whatever the
    // change might be
    func participantVideoUpdated(participant: Participant, streamId: String, videoView: VideoView) {
        print("iOSReferenceApp::participantVideoUpdated")
        if let videoInfo = participant.videoInfo?[streamId] {
            if videoInfo.active {
                // If active is not false we remove the current video view and re enable the video stream
                for (index, view) in self.participantViews.enumerated() {
                    if view.videoView == videoView {
                        participantViews.remove(at: index)
                        DispatchQueue.main.async {
                            // Remove the ParticipantView from the scroll view
                            view.removeFromSuperview()
                        }
                    }
                }
                MeetingSDK.shared.enableVideoStream(participant: participant, streamId: streamId)
            } else {
                print("iOSReferenceApp::participantVideoUpdated -- videoInfo.active was FALSE")
            }
        }
    }
    
    // This is a private utility function used to create a new ParticipantView and add it to
    // the user interface
    private func makeAndAddNewParticipantView(participant: Participant, videoView: VideoView) {
        // Adding video view to the scroll view
        let genericFrame = CGRect(x: 0, y: 0, width: 200, height: 200)
        let participantView = ParticipantView(frame:genericFrame)
        participantView.displayName = participant.displayName
        participantView.videoView = videoView
        
        participantView.videoView?.frameView?.contentMode = .scaleAspectFit
        
        // Locate the stream id
        if let videoInfo = participant.videoInfo?[videoView.streamId] {
            participantView.streamId = videoInfo.streamId
        }
        
        participantViews.append(participantView)
        
        // Adding pan gesture to make video view draggable
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panView))
        participantView.addGestureRecognizer(panGesture)
        
        // Adding pinch gesutre to make video view pinchable to resize it
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchToResize(_:)))
        participantView.addGestureRecognizer(pinchGestureRecognizer)
        
        self.scrollView.addSubview(participantView)
    }
    
    // This delegate method is received when the SDK has created a new VideoView for us in response
    // to an enableVideoStream call.    We utilize the private makeAndAddNewParticipantView function
    // (above) to add the new view to our user interface
    func participantVideoViewCreated(participant: Participant, videoView: VideoView, local: Bool) {
        print("iOSReferenceApp::videoViewCreated")
        DispatchQueue.main.async {
            self.makeAndAddNewParticipantView(participant: participant, videoView: videoView)
        }
    }
    
    // This delegate method is received when enableVideoStream is called on a VideoView that already
    // exists.   This can happen if an existing video stream is disabled and then re-enabled
    func participantVideoViewRetrieved(participant: Participant, videoView: VideoView) {
        print("iOSReferenceApp::participantVideoViewRetrieved")
        
        // If we don't have this videoView in our list of ParticipantViews, create and add
        for participantView in self.participantViews {
            if participantView.videoView == videoView {
                // we already have it, so just return
                return
            }
        }
        
        // If we get here, we don't have this VideoView in our participant views.
        // Go ahead and add it.  The active flag is likely still "false" as we will get
        // a participantVideoViewRetrieved event when the enableVideoStream API is called.
        // The active flag is set when we receive the corresponding video_stream_buffer_ready event.
    
        if let videoInfoDict = participant.videoInfo {
            for (_,videoInfo) in videoInfoDict {
                // Find corresponding videoInfo structure
                if videoInfo.streamId == videoView.streamId {
                    // add the view
                    DispatchQueue.main.async {
                        // TODO: Convert to videoview map like mac reference app
                        videoInfo.videoView?.frameView?.image = nil
                        self.makeAndAddNewParticipantView(participant: participant, videoView: videoView)
                    }
                }
            }
        }
    }
    
    // Called when a given video stream is removed from a meeting
    func participantVideoRemoved(participant: Participant, streamId: String, videoView: VideoView?) {
        for participantView in participantViews {
            if participantView.streamId == streamId {
                DispatchQueue.main.async {
                    participantView.removeFromSuperview()
                    guard let index = self.participantViews.firstIndex(of: participantView) else
                    {
                        print("iOSReferenceApp::participantVideoRemoved:  Could not find index of view to be removed")
                        return
                    }
                    self.participantViews.remove(at: index)
                    print("iOSReferenceApp::participantViews now: \(self.participantViews)")
                }
            }
        }
        print("iOSReferenceApp::participantVideoRemoved")
    }
    
    // Not used in the reference app
    func particpantVideoRemoteLayoutChanged(participant: Participant, streamId: String) {
        print("iOSReferenceApp::participantVideoLayoutChanged")
    }
    
    // When a participant is removed, we pro-actively remove all video views associated with it
    func participantRemoved(participant: Participant) {
        print("iOSReferenceApp::participantRemoved")
        
        // Remove all video streams associated with this participant
        if let videoInfoDict = participant.videoInfo {
            for (_,videoInfo) in videoInfoDict {
                participantVideoRemoved(participant: participant, streamId: videoInfo.streamId, videoView: videoInfo.videoView)
            }
        }
    }
    
    // Not used in the reference app
    func inputMeterChanged(meter: String) {
        print("iOSReferenceApp::inputMeterChanged")
    }
    
    // Not used in the reference app
    func outputMeterChanged(meter: String) {
        print("iOSReferenceApp::outputMeterChanged")
    }
    
    // Not used in the reference app
    func participantAmplitudeChanged(participant: Participant, amplitude: String, muted: Bool) {
        if let streamId = participant.audioInfo?.streamId {
            if muted {
                MeetingState.shared.mutedStreamIDs[streamId] = true
            } else {
                MeetingState.shared.mutedStreamIDs.removeValue(forKey: streamId)
            }
        }
        print("iOSReferenceApp::amplitude")
    }
}
