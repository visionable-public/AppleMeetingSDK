//
//  CMVideoStreamCondition.h
//  MeetingSDK
//
//  Created by Mamrokha Yaroslav on 30.10.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMVideoStreamCondition : NSObject

@property(strong, nonatomic)NSString * streamId;
@property(strong, nonatomic)NSString * siteName;
@property(strong, nonatomic)NSString * streamName;
@property(strong, nonatomic)NSString * userUUID;
@property(strong, nonatomic)NSString * protocol;
@property(strong, nonatomic)NSString * codec;
@property(nonatomic)uint64_t  droppedCtrl;
@property(nonatomic)uint64_t  droppedData;
@property(nonatomic)int32_t  framerate;
@property(nonatomic)int32_t  kbps;
@property(nonatomic)int32_t  upstreamLatency;
@property(nonatomic)int32_t  upstreamLoss;
@property(nonatomic)int32_t  upstreamJitter;
@property(nonatomic)int32_t  downstreamLatency;
@property(nonatomic)int32_t  downstreamLoss;
@property(nonatomic)int32_t  downstreamJitter;
@property(nonatomic)int32_t  bars;

@end

NS_ASSUME_NONNULL_END
