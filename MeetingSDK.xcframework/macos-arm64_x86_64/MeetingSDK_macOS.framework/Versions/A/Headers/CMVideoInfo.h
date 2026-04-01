//
//  VideoInfo.h
//  MeetingSDK
//
//  Created by Ron DiNapoli on 5/19/22.
//

#import <Foundation/Foundation.h>
#import "CMPTZControlInfo.h"

@class VideoView;

NS_ASSUME_NONNULL_BEGIN

@interface CMVideoInfo : NSObject

@property(strong)NSString *_streamId;
@property(nonatomic, nullable)CMPTZControlInfo * _ptzInfo;

// Initializer
-(id) initWithStreamId:(NSString *)streamId;

// Accessor Methods
-(NSString *)_site;
-(NSString *)_name;
-(NSString *)_codecName;
-(bool)_local;
-(bool)_active;
-(bool)_ptzStatus;
-(uint8_t)_layout;
-(uint32_t)_width;
-(uint32_t)_height;
-(CMPTZControlInfo * _Nullable)_controllableInfo;

-(bool)isScreenShare;
@end

NS_ASSUME_NONNULL_END
