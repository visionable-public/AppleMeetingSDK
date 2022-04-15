//
//  Utils.h
//  TestMeetingSDK
//
//  Created by Ron DiNapoli on 12/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject
+(NSData *)getVideoFrameFromBuffer:(NSString *)buffer withSize:(NSInteger) size;
@end

NS_ASSUME_NONNULL_END
