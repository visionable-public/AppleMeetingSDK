//
//  CMPTZControlInfo.h
//  MeetingSDK
//
//  Created by Yaroslav Mamrokha on 30.03.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPTZControlInfo : NSObject

@property(strong)NSString * _streamId;


-(id) initWithStreamId:(NSString *)streamId;

-(bool)_relativePan;
-(bool)_relativeTilt;
-(bool)_relativeZoom;

-(int32_t)_panStep;
-(int32_t)_tiltStep;
-(int32_t)_zoomStep;

@end

NS_ASSUME_NONNULL_END
