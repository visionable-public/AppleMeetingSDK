//
//  AudioInfo.h
//  MeetingSDK
//
//  Created by Ron DiNapoli on 5/20/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMAudioInfo : NSObject

@property(strong)NSString *_streamId;

// Initializer
-(id) initWithStreamId:(NSString *)streamId;

// Accessor Methods
-(NSString *)_site;
@end

NS_ASSUME_NONNULL_END
