//
//  CMAudioCondition.h
//  MeetingSDK
//
//  Created by Mamrokha Yaroslav on 30.10.2024.
//

#import <Foundation/Foundation.h>
#import <CMAudioStreamCondition.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMAudioCondition : NSObject

@property (strong, nonatomic) NSArray<CMAudioStreamCondition *> *audioConditions;
@property (strong, nonatomic) NSString *upstreamCodec;
@property (strong, nonatomic) NSString *downstreamCodec;
@property (nonatomic) uint64_t kBytesReceived;
@property (nonatomic) uint64_t kBytesSent;
@property (nonatomic) uint64_t dataBytesDropped;
@property (nonatomic) uint64_t ctrlBytesDropped;
@property (nonatomic) uint32_t bars;
@property (nonatomic) uint32_t connectionStatus;
@property (nonatomic) uint32_t upstreamFps;
@property (nonatomic) uint32_t upstreamKbps;
@property (nonatomic) uint32_t upstreamLoss;
@property (nonatomic) uint32_t upstreamLatency;
@property (nonatomic) uint32_t upstreamJitter;
@property (nonatomic) uint32_t downstreamFps;
@property (nonatomic) uint32_t downstreamKbps;
@property (nonatomic) uint32_t downstreamLoss;
@property (nonatomic) uint32_t downstreamLatency;
@property (nonatomic) uint32_t downstreamJitter;
@property (nonatomic) uint32_t lastNatArrival;

@end

NS_ASSUME_NONNULL_END
