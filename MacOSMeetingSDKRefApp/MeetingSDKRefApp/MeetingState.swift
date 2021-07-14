//
//  MeetingState.swift
//  MeetingSDKRefApp
//
//  Created by Ron DiNapoli on 4/17/21.
//
//  A singleton class used to keep track of Settings and various aspects of the Meeting
//

import Cocoa

class MeetingState: NSObject {
    // The shared instance of the MeetingState class
    public static let shared = MeetingState()

    // Settings we need to know for input/output
    var audioInputDeviceName:String? = nil
    var audioOutputDeviceName:String? = nil
    
    var videoDevicesUsed:[String:String]? = nil
    var videoWindows:[VideoStreamViewController] = []
    var audioStreamVolumes:[String:Int]=[:]
    
    public func resetVideoDevices() {
        if videoDevicesUsed == nil {
            videoDevicesUsed = [:]
        } else {
            videoDevicesUsed!.removeAll()
        }
    }
    
    public func addVideoDevice(deviceName:String, codec:String) {
        videoDevicesUsed?[deviceName] = codec
    }
    
    public func printAudioVideoSettings() {
        print("MeetingState:  Using the following devices")
        print("     AUDIO INPUT: \(audioInputDeviceName ?? "Unknown")")
        print("     AUDIO OUTPUT: \(audioOutputDeviceName ?? "Unknown")")
        if let videoDevices = videoDevicesUsed {
            for (video,codec) in videoDevices {
                print("     VIDEO DEVICE: \(video) with codec: \(codec)")
            }
        }
    }
    
}
