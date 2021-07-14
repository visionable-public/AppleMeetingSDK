//
//  SampleHandler.m
//  ScreenShareExtension
//
//  Created by Ron DiNapoli on 5/5/21.
//



#import "SampleHandler.h"
#import <MeetingSDK_iOS/MeetingSDKScreenSharing.h>

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    [[MeetingSDKScreenSharing sharedInstance] setAppGroupId:@"group.com.visionable.sdk.screensharing"];
    [[MeetingSDKScreenSharing sharedInstance] broadcastStartedWithSetupInfo:setupInfo];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    [[MeetingSDKScreenSharing sharedInstance] broadcastPaused];
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    [[MeetingSDKScreenSharing sharedInstance] broadcastResumed];
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    // Clean up any files
    [[MeetingSDKScreenSharing sharedInstance] broadcastFinished];
}


- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    [[MeetingSDKScreenSharing sharedInstance] processSampleBuffer:sampleBuffer withType:sampleBufferType];
}

@end
