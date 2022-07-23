//
//  Participant.h
//  MeetingSDK
//
//  Created by Ron DiNapoli on 5/19/22.
//

#import <Foundation/Foundation.h>
#import "CMAUdioInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMParticipant : NSObject

@property(strong)NSString *userUUID;

// Initializer
-(id) initWithUserUUID:(NSString *)userUUID;

// Acessor Methods
-(NSString *)_displayName;
-(bool)_isLocal;
-(NSDictionary *)_videoInfo;
-(CMAudioInfo *)_audioInfo;

@end

NS_ASSUME_NONNULL_END
