//
//  MemberEditView.h
//  TuyaSmart
//
//  Created by fengyu on 15/3/10.
//  Copyright (c) 2015年 Tuya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemberEditView : UIView



- (NSString *)username;
- (NSString *)comments;
- (void)setup:(TuyaSmartMemberModel *)member;

@end
