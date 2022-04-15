//
//  MeetingSDKScreenSharing.h
//  MeetingSDK-iOS
//
//  Define a singleton class that contains the implementation of screen sharing
//  functionality for a screen sharing plugin.
//
//  Created by Ron DiNapoli on 6/7/21.
//

#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MeetingSDKScreenSharing : NSObject


/*! @discussion The shared instance for this singleton.   Always use this static method to get the shared instance of MeetingSDKScreenSharing before calling any of the other methods in this class.
 */
+(MeetingSDKScreenSharing *)sharedInstance;

/*! @discussion Tells the MeetingSDKScreenSharing class what AppGroup ID to use when storing individual frames coming from the operating system
    @param argAppGroup  The name of the AppGroup ID to use
 */
- (void)setAppGroupId:(NSString *)argAppGroup;

/*! @discussion The method to call when you receive the broadcastStartedWithSetupInfo callback in your screen sharing extension
    @param setupInfo  The dictionary of key-value pairs that was passed to the broadcastStartedWithSetupInfo callback in your screen sharing extension
 */
- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo;

/*! @discussion The method to call when you receive the broadcastPaused callback in your screen sharing extension
 */
- (void)broadcastPaused;

/*! @discussion The method to call when you receive the broadcastResumed callback in your screen sharing extension
 */
- (void)broadcastResumed;

/*! @discussion The method to call when you receive the broadcastFinished callback in your screen sharing extension
 */
- (void)broadcastFinished;

/*! @discussion The method to call when you receive the broadcastPaused callback in your screen sharing extension
    @param sampleBuffer  The actual frame data received from iOS by your screen sharing extension.    Simply pass the argument received by your corresponding callback to this method.
    @param sampleBufferType  The actual frame data type received from iOS by your screen sharing extension.    Simply pass the argument received by your corresponding callback to this method.
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

@end

NS_ASSUME_NONNULL_END
