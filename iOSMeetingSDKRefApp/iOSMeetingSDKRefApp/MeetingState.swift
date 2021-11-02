//
//  MeetingState.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 5/2/21.
//

import UIKit

// Keep track of some informaton needed for the meeting
class MeetingState: NSObject {
    // The shared instance of the MeetingState class
    public static let shared = MeetingState()

    // Settings we need to know for input/output
    var audioInputDeviceName: String? = nil
    var audioOutputDeviceName: String? = nil
    
    var videoDevicesUsed: [String: String] = [:]
    var audioStreamVolumes: [String: Int]=[:]
    var mutedStreamIDs: [String: Bool]=[:]
    
    // Set to true when we have successfully joined a meeting
    var meetingIsActive = false
    
    public func addVideoDevice(deviceName: String, codec: String) {
        videoDevicesUsed[deviceName] = codec
    }
    
    // Used for debugging purposes
    public func printAudioVideoSettings() {
        print("MeetingState:  Using the following devices")
        print("     AUDIO INPUT: \(audioInputDeviceName ?? "Unknown")")
        print("     AUDIO OUTPUT: \(audioOutputDeviceName ?? "Unknown")")
        for (video,codec) in videoDevicesUsed {
            print("     VIDEO DEVICE: \(video) with codec: \(codec)")
        }
    }
    
}
