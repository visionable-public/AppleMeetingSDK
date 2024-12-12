//
//  CMAudioCondition.h
//  MeetingSDK
//
//  Created by Mamrokha Yaroslav on 30.10.2024.
//

#import <Foundation/Foundation.h>
#import "CMAudioStreamCondition.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMAudioCondition : NSObject

@property (strong, nonatomic) NSArray<CMAudioStreamCondition *> *audioConditions;
@property (strong, nonatomic) NSString *upstreamCodec;
@property (strong, nonatomic) NSString *downstreamCodec;
@property (nonatomic) uint64_t kBytesReceived;
@property (nonatomic) uint64_t kBytesSent;
@property (nonatomic) uint64_t dataBytesDropped;
@property (nonatomic) uint64_t ctrlBytesDropped;
@property (nonatomic) int32_t bars;
@property (nonatomic) int32_t connectionStatus;
@property (nonatomic) int32_t upstreamFps;
@property (nonatomic) int32_t upstreamKbps;
@property (nonatomic) int32_t upstreamLoss;
@property (nonatomic) int32_t upstreamLatency;
@property (nonatomic) int32_t upstreamJitter;
@property (nonatomic) int32_t downstreamFps;
@property (nonatomic) int32_t downstreamKbps;
@property (nonatomic) int32_t downstreamLoss;
@property (nonatomic) int32_t downstreamLatency;
@property (nonatomic) int32_t downstreamJitter;
@property (nonatomic) int32_t lastNatArrival;

@end

NS_ASSUME_NONNULL_END
