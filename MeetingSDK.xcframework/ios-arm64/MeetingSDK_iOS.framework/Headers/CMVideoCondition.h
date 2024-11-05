//
//  CMVideoCondition.h
//  MeetingSDK
//
//  Created by Mamrokha Yaroslav on 30.10.2024.
//

#import <Foundation/Foundation.h>
#import <CMVideoStreamCondition.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMVideoCondition : NSObject

@property (strong, nonatomic) NSArray<CMVideoStreamCondition *> *streamConditions;
@property (nonatomic) uint64_t kBytesReceived;
@property (nonatomic) uint64_t kBytesSent;
@property (nonatomic) uint64_t dataBytesDropped;
@property (nonatomic) uint64_t ctrlBytesDropped;
@property (nonatomic) uint32_t cpuUsage;
@property (nonatomic) uint32_t bars;
@property (nonatomic) uint32_t lastNatArrival;
@property (nonatomic) uint32_t connectionStatus;

@end

NS_ASSUME_NONNULL_END
