//
//  MeetingAPI.h
//  MeetingSDK-macOS
//
//  Created by Ron DiNapoli on 11/18/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MeetingSDK;
@interface MeetingAPI : NSObject
{
    
@private
    void (^_completionHandler)(bool someParameter);
    NSArray* deviceList;
}

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

typedef void (^AudioVideoCallback)(NSString *event_name,NSString *event_data);
typedef void (^TraceLogCallback)(NSInteger level, NSString *message);

+(MeetingAPI *)sharedInstance; 

//- Callbacks


-(void)enableInlineAudioVideoLogging:(BOOL) enable;

/*! @discussion Set callback for log
    @param callback  callback for log
 */
-(void)setLogCallback: (TraceLogCallback)callback;

/*! @discussion Set notification callback
    @param callback  callback for notification
*/
-(void)setNotificationCallback: (void (^)(NSString*, NSString* ))callback;

/*! @discussion Set audio callback
    @param callback callback for audio
 */
-(void)setAudioCallback: (AudioVideoCallback)callback;

/*! @discussion Set callback for video
    @param callback callback for video
*/
-(void)setVideoCallback: (AudioVideoCallback)callback;


//- Functions

/*! @discussion Get key. Timeout after 60 seconds if no response.
    @param server  server info
    @param mtg_guid meeting guif
    @param handler  success callback with key
 */
- (void)asyncGetKey:(NSString*)server mtg_guid:(NSString*)mtg_guid handler:(void(^)(bool success,NSString* key))handler;

/*! @discussion Basic join a meeting call. Return false if error. Timeout after 60 seconds if no response.
    @param name  user name.
    @param userUUID  userUUID
    @param handler  success callback
 */
- (void)joinMeeting:(NSString*)name userUUID:(NSString*)userUUID handler:(void(^)(bool))handler;

/*! @discussion Initializes a meeting. Timeout after 60 seconds if no response.
    @param guid  meeting guid
    @param server server id
    @param handler  success callback
 */
- (void)initializeMeeting:(NSString*)guid server:(NSString*)server handler:(void(^)(bool))handler;

/*! @discussion Return the devices. Timeout after 60 seconds if no response.
    @param handler  callback with devices
 */
- (void)getDevices:(void(^)(NSString*))handler;

/*! @discussion Return the devices. Timeout after 60 seconds if no response.
    @param handler  callback with devices
 */
- (void)getDevicesForVideo:(void(^)(NSString*))handler;

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

/*! @discussion Start video capture by the specified device
    @param deviceID  device id
    @param handler  returns true if success or false if failed
 */

- (void)enableVideoCapture:(NSString*)deviceID withMode:(NSString *)mode handler:(void(^)(bool))handler;

/*! @discussion Set the bundle id and the app group id used by the Screen Sharing extension
        @param bundleId The bundle id of the screen sharing extension
        @param appGroupId The App Group identifier used to share data between the application and the screen sharing extension
 
 */
-(void) initializeScreenCaptureExtension:(NSString *)bundleId withAppGroup:(NSString *)appGroupId;

/*! @discussion Stop capturing via the camera
    @param deviceID device id
 */
- (bool)disableVideoCapture:(NSString*)deviceID;


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
    @param width width
    @param height height
    @param colorspace color space
*/

- (bool)enableVideoStream:(NSString*)streamID width:(int)width height:(int)height colorspace:(NSString*)colorspace;

/*! @discussion disable specified video stream
    @param streamID device id
 */
- (bool)disableVideoStream:(NSString*)streamID;

/*! @discussion Return true if specified stream is ready
    @param streamid stream id
 */
- (int)videoFrameReady:(NSString*)streamid;

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


/*! @discussion Manually set the stored audio stream ID
    @param newStreamID New stream id
 */

- (void)setAudioStreamID:(NSString*)newStreamID;

/*! @discussion Manually set the stored video stream ID
    @param newStreamID  New stream id
 */
- (void)setSelectedVideoStreamID:(NSString*)newStreamID;

- (NSString *)getAudioDevices;
- (NSString *)getVideoDevices;

/*! @discussion set the debug trace level (1-7) for IGAudio
    @param level  New level value (1-7)
 */
- (void)audioSetTraceLevel:(int) level;


/*! @discussion set the debug trace level (1-7) for IGVideo
    @param level  New level value (1-7)
 */
- (void)videoSetTraceLevel:(int) level;

- (void)videoTraceOutputHistory:(NSString *)filename;
- (void)audioTraceOutputHistory:(NSString *)filename;

-(uint64_t)playSound:(NSData *)wavdata;
-(bool)stopSound:(uint64_t) data;
@end

NS_ASSUME_NONNULL_END
