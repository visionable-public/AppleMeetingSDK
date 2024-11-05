//
//  CMAudioStreamCondition.h
//  MeetingSDK
//
//  Created by Mamrokha Yaroslav on 30.10.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMAudioStreamCondition : NSObject

@property(strong, nonatomic)NSString * streamId;
@property(strong, nonatomic)NSString * siteName;
@property(strong, nonatomic)NSString * streamName;
@property(strong, nonatomic)NSString * userUUID;
@property(strong, nonatomic)NSString * protocol;
@property(strong, nonatomic)NSString * codec;
@property(nonatomic)uint32_t framerate;
@property(nonatomic)uint32_t kbps;
@property(nonatomic)uint32_t droppedCtrl;
@property(nonatomic)uint32_t droppedData;
@property(nonatomic)uint32_t upstreamLatency;
@property(nonatomic)uint32_t upstreamLoss;
@property(nonatomic)uint32_t upstreamJitter;
@property(nonatomic)uint32_t downstreamLatency;
@property(nonatomic)uint32_t downstreamLoss;
@property(nonatomic)uint32_t downstreamJitter;
@property(nonatomic)uint32_t bars;

@end

NS_ASSUME_NONNULL_END
