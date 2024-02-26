//
//  MeetingAPI.h
//  MeetingSDK-macOS
//
//  Created by Ron DiNapoli on 11/18/20.
//

#import <Foundation/Foundation.h>
#import "CMVideoInfo.h"
#import "CMParticipant.h"

NS_ASSUME_NONNULL_BEGIN

@interface MeetingAPI : NSObject

// TODO: Remove unneeded properties
//-Properties

@property (readonly) NSString* defaultServer;
@property (readonly) NSString* defaultName;
@property (readonly) NSString* lastError;
@property (readonly) NSString* userName;
@property (readonly) NSString* userEmail;
@property (readonly) NSString* mtgServer;
@property (readonly) NSString* mtgGuid;
@property (readonly) NSString* mtgKey;
@property (readonly) NSString* audioStreamID;
@property (readonly) NSString* currentVideoStreamID;
@property (readonly) NSMutableDictionary* videoStreamIDS;

@property(assign)BOOL autoEnableVideoStream;
@property(assign)BOOL autoEnableVideoCapture;
@property(assign)BOOL autoEnableAudioInput;
@property(assign)BOOL autoEnableAudioOutput;

@property(assign)NSObject *_Nullable delegate;

+(MeetingAPI *)sharedInstance; 

//- Callbacks


-(void)enableInlineAudioVideoLogging:(BOOL) enable;

//- Functions

/*! @discussion Basic join a meeting call. Return false if error. Timeout after 60 seconds if no response.
    @param name  user name.
    @param userUUID  userUUID
    @param handler  success callback
 */
- (void)joinMeeting:(NSString *)server meetingUUID:(NSString *) meetingUUID key:(NSString *)key
           userUUID:(NSString *)userUUID name:(NSString *)name handler:(void(^)(bool))handler;

/*! @discussion Initializes a meeting. Timeout after 60 seconds if no response.
    @param guid  meeting guid
    @param server server id
    @param handler  success callback
 */
- (void)initializeMeeting:(NSString*)guid server:(NSString*)server handler:(void(^)(bool,NSString *))handler;
- (void)initializeMeetingWithToken:(NSString * _Nullable)token server:(NSString *)server uuid:(NSString *)meetingUUID handler:(void (^)(bool,NSString *))handler;
- (void)resolveUCSServer:(NSString *)server uuid:(NSString *)meetingUUID handler:(void (^)(NSString *))handler;

/*! @discussion Exits a meeting
 */
- (void)exitMeeting;

/*! @discussion Call this to enable the audio output and input devices. Normally, you pass in the device name and id, but in the case of an iPhone, there is just "Default device"
    @param deviceName device name
    @param deviceID device id
 */
- (bool)enableAudioInput:(NSString*)deviceName deviceID:(NSString*)deviceID;

/*! @discussion Call this to disable the audio output and input devices. Normally, you pass in the device name and id, but in the case of an iPhone, there is just "Default device"
    @param deviceName device name
    @param deviceID device name
 */
- (bool)disableAudioInput:(NSString*)deviceName deviceID:(NSString*)deviceID;

/*! @discussion Call this to enable the audio output and input devices. Normally, you pass in the device name and id, but in the case of an iPhone, there is just "Default device"
    @param deviceName device name
    @param deviceID device id
 */
- (bool)enableAudioOutput:(NSString*)deviceName deviceID:(NSString*)deviceID;

/*! @discussion Disable the specified mic
    @param deviceName device name
    @param deviceID  device id
 */
- (bool)disableAudioOutput:(NSString*)deviceName deviceID:(NSString*)deviceID;

- (bool)enableAudioInputPreview:(NSString *)deviceName;
- (bool)disableAudioInputPreview:(NSString *)deviceName;
- (bool)enableAudioOutputPreview:(NSString *)deviceName withSoundPath:(NSString *)soundPath;
- (bool)disableAudioOutputPreview:(NSString *)deviceName;

/*! @discussion Start video capture by the specified device
    @param deviceID  device id
    @param handler  returns true if success or false if failed
 */

- (void)enableVideoCapture:(NSString*)deviceID withMode:(NSString *)mode andBlurring:(bool)blurring handler:(void(^)(bool))handler;

#if !defined(MACOS)
/*! @discussion Set the bundle id and the app group id used by the Screen Sharing extension
        @param bundleId The bundle id of the screen sharing extension
        @param appGroupId The App Group identifier used to share data between the application and the screen sharing extension
 
 */
-(void) initializeScreenCaptureExtension:(NSString *)bundleId withAppGroup:(NSString *)appGroupId;
#endif

/*! @discussion Stop capturing via the camera
    @param deviceID device id
 */
- (bool)disableVideoCapture:(NSString*)deviceID;

- (void)enableVideoPreview:(NSString *)deviceID withMode:(NSString *)mode handler:(void(^)(bool))handler;
- (bool)disableVideoPreview:(NSString *)deviceID;

- (bool)enableWindowSharing:(NSString*)windowID withMode:(NSString *)mode;
- (bool)disableWindowSharing:(NSString*)windowID;

/*! @discussion Start video capture from specified URL
    @param url  URL of video source
    @param mode Codec to be used
    @param handler  returns true if success or false if failed
 */
- (void)enableNetworkVideo:(NSString*)url withMode:(NSString *)mode name:(NSString *)name handler:(void(^)(bool))handler;


/*! @discussion*     Stop sending video from network feed
    @param url url of connection to stop
 */
- (bool)disableNetworkVideo:(NSString*)url;


/*! @discussion Start displaying the incoming video stream
    @param streamID stream id

*/

- (bool)enableVideoStream:(NSString*)streamID;

/*! @discussion disable specified video stream
    @param streamID device id
 */
- (bool)disableVideoStream:(NSString*)streamID;

/*! @discussion Temporarily stop sending videoFrameReady delegate method callbacks for specified stream
    @param streamID stream id
*/
- (void)pauseVideoFrameProcessing:(NSString*)streamID;

/*! @discussion Resume sending videoFrameReady delegate method callbacks for specified stream
    @param streamID device id
 */
- (void)resumeVideoFrameProcessing:(NSString*)streamID;

/*! @discussion Set volume of the audio stream. 0 to mute
    @param streamID stream id
    @param volume volume level
 */
- (bool)setAudioStreamVolume:(NSString*)streamID volume:(int)volume;


/*! @discussion Set volume of the input stream. 0 to mute
    @param device Name of the device
    @param volume volume level (0-100)
 */
- (bool)setAudioInputVolume:(NSString*)device volume:(int)volume;


/*! @discussion Set volume of the output stream. 0 to mute
    @param device Name of the device
    @param volume volume level (0-100)
 */
- (bool)setAudioOutputVolume:(NSString*)device volume:(int)volume;


- (NSArray *)getAudioInputDevices;
- (NSArray *)getAudioOutputDevices;
- (NSArray *)getVideoDevices;
- (NSArray *)getSupportedVideoSendResolutions:(NSString *)device;

#if defined(MACOS)
- (NSDictionary *) getWindowList;
- (NSData *) getWindowThumbnail:(NSString *)windowId withFormat:(NSString* )format inPath:(NSString *)dirPath withWidth:(int) width andHeight:(int) height;
#endif

- (CMParticipant *_Nullable)getLocalParticipant;

- (NSArray *)getParticipants;

- (void)enableCombinedLogs:(bool) enable;
- (void)enableLogForwarding:(bool) enable;
- (void)enableActiveLogging:(NSString *) filename;
- (void)setTraceLevel:(int) level;
- (void)audioSetTraceLevel:(int) level;
- (void)videoSetTraceLevel:(int) level;
- (void)videoTraceOutputHistory:(NSString *)filename;
- (void)audioTraceOutputHistory:(NSString *)filename;
- (void)coreMeetingTraceOutputHistory:(NSString *)filename;
- (void)coreMeetingLog:(NSString *)message;

- (bool)setLogDirectory:(NSString *)path;
- (bool)deleteLogFile:(NSString *)fileName;
- (bool)deleteAllLogFiles;
- (bool)resetCurrentLogFile;
- (bool)trimCurrentLogFile:(int)numBytes;
- (bool)flushCurrentLogFile;
- (NSArray *)getLogFiles;

- (NSString *) getLastError;

-(uint64_t)playSound:(NSData *)wavdata;
-(bool)stopSound:(uint64_t) data;

-(CMParticipant *_Nullable) findParticipantByVideoStreamId:(NSString *)streamId;
-(CMParticipant *_Nullable) findParticipantByAudioStreamId:(NSString *)streamId;
-(CMVideoInfo *_Nullable) findVideoInfoByStreamId:(NSString *)streamId;

@end

NS_ASSUME_NONNULL_END
