//
//  TYMemberListView.m
//  TuyaSmart
//
//  Created by 冯晓 on 16/1/7.
//  Copyright © 2016年 Tuya. All rights reserved.
//

#import "TYMemberListView.h"
#import "TYMemberListCell.h"
#import "TPEmptyView.h"
#import "TPSegmentedControl.h"


@interface TYMemberListView() <UITableViewDataSource,UITableViewDelegate,TPSegmentedControlDelegate>

@property (nonatomic, assign) TYMemberCurrentType currentType;
@property (nonatomic, strong) UIButton            *shareButton;
@property (nonatomic, strong) TPEmptyView         *emptyView;
@property (nonatomic, strong) TPSegmentedControl  *segmentedControl;

@end


@implementation TYMemberListView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = MAIN_BACKGROUND_COLOR;
        
        [self addSubview:self.segmentedControl];
        [self addSubview:self.tableView];
        [self.tableView addSubview:self.emptyView];
        [self addSubview:self.shareButton];
        
        [self reloadTableView];
        
        _currentType = TYMemberSend;
    }
    return self;
}

- (void)reloadData {
    [self reloadTableView];
}

- (UITableView *)tableView {
    if (!_tableView) {
    
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.segmentedControl.height, APP_SCREEN_WIDTH,0)
                                                  style:UITableViewStyleGrouped];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:[TYMemberListCell class] forCellReuseIdentifier:@"MemberTableViewCell"];
        
    }
    return _tableView;
}


#pragma mark - TPSegmentedControlDelegate
- (void)didSelectCurrentIndex:(NSInteger)index {
    if (index == 0) {
        _currentType = TYMemberSend;
    } else {
        _currentType = TYMemberReceive;
    }
    
    _currentIndex = index;
    [self reloadTableView];

    
}

- (void)setCurrentSelectIndex:(NSInteger)index {
    [_segmentedControl changeToIndex:index];
}

- (TPSegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        NSArray *titleArr = @[NSLocalizedString(@"ty_add_share_tab1", @""), NSLocalizedString(@"ty_add_share_tab2", @"")];

        _segmentedControl = [[TPSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH, 44) items:titleArr];
        _segmentedControl.delegate = self;
    }
    return _segmentedControl;
}

- (TPEmptyView *)emptyView {
    if (!_emptyView) {
        CGRect emptyViewFrame = CGRectMake(0, 44, APP_SCREEN_WIDTH, self.height - 44 - 64 - 40);
        _emptyView = [[TPEmptyView alloc] initWithFrame:emptyViewFrame title:NSLocalizedString(@"no_share", @"") imageName:@"ty_list_empty"];
    }
    return _emptyView;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [TPViewUtil buttonWithFrame:CGRectMake(0, self.height - APP_TOOL_BAR_HEIGHT, APP_SCREEN_WIDTH, APP_TOOL_BAR_HEIGHT) fontSize:15 bgColor:[UIColor whiteColor] textColor:HEXCOLOR(0x788088)];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH, 0.5)];
        lineView.backgroundColor = SEPARATOR_LINE_COLOR;
        [_shareButton addSubview:lineView];
        
        [_shareButton setTitle:NSLocalizedString(@"new_share", @"") forState:UIControlStateNormal];
        [_shareButton addTarget:self action:@selector(addNewMember) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

#pragma mark - custom action

- (void)addNewMember {
    [self.delegate addNewMember:self];
}

- (void)reloadTableView {
    
    if ((_currentIndex == 0 && self.dataSource.memberList.count > 0)
        || (_currentIndex == 1 && self.dataSource.receiveMemberList.count > 0)) {
        self.emptyView.hidden = YES;
    } else {
        self.emptyView.hidden = NO;
    }
    
    if (_currentIndex == 0) {
        _shareButton.hidden = NO;
        [_emptyView setTitle:NSLocalizedString(@"no_share", nil)];
        _tableView.height = self.height - self.segmentedControl.height - self.shareButton.height;
    } else {
        _shareButton.hidden = YES;
        [_emptyView setTitle:NSLocalizedString(@"ty_share_empty_device", nil)];
        _tableView.height = self.height - self.segmentedControl.height;
    }
    
    
    
    [_tableView reloadData];
}




- (TuyaSmartMemberModel *)getMemberModel:(NSIndexPath *)indexPath {
    if (_currentIndex == 0) {
        return [self.dataSource.memberList objectAtIndex:indexPath.row];
    } else {
        return [self.dataSource.receiveMemberList objectAtIndex:indexPath.row];
    }
}

- (TYMemberCurrentType)getCurrentType {
    if (_currentIndex == 0) {
        return TYMemberSend;
    } else {
        return TYMemberReceive;
    }
}


- (void)removeMember:(TuyaSmartMemberModel *)member {
    if (_currentIndex == 0) {
        
        NSMutableArray *memberList = [NSMutableArray arrayWithArray:self.dataSource.memberList];
        [memberList removeObject:member];
        self.dataSource.memberList = memberList;
        
    } else {
    
        
        NSMutableArray *memberList = [NSMutableArray arrayWithArray:self.dataSource.receiveMemberList];
        [memberList removeObject:member];
        self.dataSource.receiveMemberList = memberList;
        
        
    }
}



#pragma mark UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (_currentIndex == 0 && self.dataSource.memberList.count > 0) {
            return NSLocalizedString(@"ty_add_share_tab1_note", @"");
        } else if (_currentIndex == 1 && self.dataSource.receiveMemberList.count > 0) {
            return NSLocalizedString(@"ty_add_share_tab2_note", @"");
        }
    }
    
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_currentIndex == 0) {
        return self.dataSource.memberList.count;
    } else {
        return self.dataSource.receiveMemberList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TYMemberListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberTableViewCell"];
    
    TuyaSmartMemberModel *member = [self getMemberModel:indexPath];
    [cell setMember:member];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 55;
    } else {
        return 14;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 14;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        TuyaSmartMemberModel *member = [self getMemberModel:indexPath];
        
        NSString *title;

        if (_currentIndex == 0) {
            title = [NSString stringWithFormat:NSLocalizedString(@"delete_member_tips", nil), member.nickName];
        } else {
            title = [NSString stringWithFormat:NSLocalizedString(@"ty_delete_share_pop", nil), member.nickName];
        }
        
        WEAKSELF_AT
        [UIAlertView bk_showAlertViewWithTitle:title
                                       message:nil
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:@[NSLocalizedString(@"confirm", nil)]
                                       handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                           
                                           
                                           if (buttonIndex == 1) {
                                               
                                               [weakSelf_AT deleteMemberWithMember:member success:^{
                                                   [weakSelf_AT reloadTableView];
                                               } failure:^{
                                                   [weakSelf_AT reloadTableView];

                                               }];
                                               
                                               
                                               

                                           } else {
                                               [weakSelf_AT reloadTableView];
                                           }
                                           
                                       }];
        
    }
    
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.delegate memberListView:self didSelectRowAtModel:[self getMemberModel:indexPath] currentType:[self getCurrentType]];
}

- (void)deleteMemberWithMember:(TuyaSmartMemberModel *)member success:(TYSuccessHandler)success failure:(TYFailureHandler)failure {
    
    WEAKSELF_AT
    [TPProgressUtils showMessag:NSLocalizedString(@"loading", nil) toView:nil];
    
    [self.delegate memberListView:self deleteRowWithMember:member currentType:[self currentType] success:^{
        [weakSelf_AT removeMember:member];
        
        [TPProgressUtils hideHUDForView:nil animated:YES];
        
        if (success) {
            success();
        }
        
    } failure:^(NSError *error) {
        [TPProgressUtils hideHUDForView:nil animated:YES];
        [TPProgressUtils showError:NSLocalizedString(@"new_share_failure", @"")];
        
        if (failure) {
            failure();
        }
    }];
    
    
}







@end
