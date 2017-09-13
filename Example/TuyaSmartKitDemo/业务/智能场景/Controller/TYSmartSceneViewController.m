//
//  SmartSceneViewController.m
//  TuyaSmartPublic
//
//  Created by XuChengcheng on 16/7/4.
//  Copyright © 2016年 Tuya. All rights reserved.
//

#import "TYSmartSceneViewController.h"
#import "TYSmartSceneTableViewCell.h"
#import "TYAddSceneViewController.h"
#import "TYSceneActionView.h"
#import "TYSceneHeaderView.h"

#define kHasCloseEditScene @"kHasCloseEditScene"

@interface TYSmartSceneViewController () <SWTableViewCellDelegate, TYSceneActionViewDelegate, TYSceneHeaderViewDelegate>

@property (nonatomic, strong) SWTableViewCell *swipeCell;
@property (nonatomic, strong) NSMutableArray *devList;
@property (nonatomic, strong) TYSceneActionView *actionView;
@property (nonatomic, strong) TYSceneHeaderView *headerView;
@property (nonatomic, strong) TuyaSmartScene *smartScene;

@end

#define SmartSceneTableViewCellIdentifier @"SmartSceneTableViewCellIdentifier"

@implementation TYSmartSceneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    
    [self showLoadingView];
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *editScene = [TYUserDefault getPreUserDefault:kHasCloseEditScene];
    if (editScene.length == 0) {
        self.tableView.tableHeaderView = _headerView;
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self reloadTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)devList {
    if (!_devList) {
        _devList = [NSMutableArray new];
    }
    return _devList;
}

- (void)initView {
    self.view.backgroundColor = MAIN_BACKGROUND_COLOR;
    
    [self.view addSubview:self.tableView];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1) {
        self.tableView.frame = CGRectMake(0, APP_TOP_BAR_HEIGHT, APP_CONTENT_WIDTH, APP_VISIBLE_HEIGHT);
    } else {
        self.tableView.frame = CGRectMake(0, APP_TOP_BAR_HEIGHT, APP_CONTENT_WIDTH, APP_VISIBLE_HEIGHT - APP_TAB_BAR_HEIGHT);
    }
    
    _headerView = [[TYSceneHeaderView alloc] initWithFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH, 148)];
    _headerView.delegate = self;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH, 20)];
    self.tableView.tableFooterView = footerView;
    
    WEAKSELF_AT
    [self.tableView bk_whenTapped:^{
        if (weakSelf_AT.swipeCell && !weakSelf_AT.swipeCell.isUtilityButtonsHidden) {
            [weakSelf_AT.swipeCell hideUtilityButtonsAnimated:YES];
        }
    }];
    
    //待修改
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceDpsUpdate:)
                                                 name:kNotificationDeviceDpsUpdate
                                               object:nil];
    
    [TPNotification addObserver:self
                       selector:@selector(reload)
                          names:@[kNotificationSmartSceneListUpdate,
                                  kNotificationGatewayListRefreshed]
                         object:nil];
    
    [TPNotification addObserver:self
                       selector:@selector(refreshDeviceInfo:)
                          names:@[kNotificationGatewayInfoUpdate,
                                  kNotificationGatewayDeviceUpdate,
                                  kNotificationGatewayRemoved
                                  ]
                         object:nil];
}

- (void)refreshDeviceInfo:(NSNotification *)notification {
    NSDictionary *object = notification.object;
    
    NSString *gwId = [object objectForKey:@"gwId"];
    
    if ([self.devList containsObject:gwId]) {
        
        [self reload];
    }
}

- (NSString *)titleForCenterItem {
    return NSLocalizedString(@"ty_smart_scene", @"");
}

- (UIView *)customViewForRightItem {
    
    UIView *rightCustomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    UIImageView *settingImageView = [TPViewUtil imageViewWithFrame:CGRectMake(100 - 36, 4, 36, 36) image:[UIImage imageNamed:@"ty_add"]];
    [rightCustomView addSubview:settingImageView];
    [rightCustomView addGestureRecognizer:[TPViewUtil singleFingerClickRecognizer:self sel:@selector(addSceneViewController)]];
    settingImageView.image = [settingImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    settingImageView.tintColor = TOP_BAR_TEXT_COLOR;
    return rightCustomView;
}

- (void)reload
{
    WEAKSELF_AT
    [[TuyaSmartSceneManager sharedInstance] getSceneList:^(NSArray<TuyaSmartSceneModel *> *list) {
        at_dispatch_async_on_default_global_thread(^{
            weakSelf_AT.dataSource = [NSMutableArray arrayWithArray:list];
            [weakSelf_AT.devList removeAllObjects];
            [weakSelf_AT.dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                TuyaSmartSceneModel *model = (TuyaSmartSceneModel *)obj;
                [weakSelf_AT.devList addObjectsFromArray:model.devList];
            }];
            at_dispatch_async_on_main_thread(^{
                [weakSelf_AT reloadTable];
            });
        });
    } failure:^(NSError *error) {
        [weakSelf_AT hideLoadingView];
        [weakSelf_AT stopPullToRefreshAnimation];
        [TPProgressUtils showError:error];
    }];
}

- (void)reloadTable {
    
    [self hideLoadingView];
    [self stopPullToRefreshAnimation];
    
    [super reloadTable];
}

- (void)addSceneViewController {
    
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
    }
    
    TYAddSceneViewController *addSceneViewController = [[TYAddSceneViewController alloc] init];
    addSceneViewController.isAdd = YES;
    [self presentViewController:[[TPNavigationController alloc] initWithRootViewController:addSceneViewController] animated:YES completion:nil];
}

//是否显示下拉刷新
- (BOOL)showPullToRefresh {
    return YES;
}

//是否显示上拉刷新
- (BOOL)showInfinite {
    return NO;
}

- (void)deviceDpsUpdate:(NSNotification *)notification {
    
    NSString *devId     = [notification.object objectForKey:@"devId"];
    NSDictionary *dps   = [notification.object objectForKey:@"dps"];
    
    NSLog(@"--------dps : %@, actions : %@", dps, devId);
    
    if (_actionView != nil) {
        [_actionView updateCellStateWithDevId:devId dps:dps];
    }
}

- (IBAction)executeButtonClicked:(UIButton *)sender {
    
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
        return;
    }
    
    TuyaSmartSceneModel *model = self.dataSource[sender.tag];
    
    BOOL removed = [model getDeviceRemovedStatus];
    
    if (removed) {
        
        TYAddSceneViewController *addSceneViewController = [[TYAddSceneViewController alloc] init];
        
        TuyaSmartSceneModel *model = self.dataSource[sender.tag];
        addSceneViewController.model = model;
        addSceneViewController.isAdd = NO;
        
        [self presentViewController:[[TPNavigationController alloc] initWithRootViewController:addSceneViewController] animated:YES completion:nil];
        
        return;
    }
    
    BOOL offline = [model getAllOfflineStatus];
    
    if (offline) {
        [TPProgressUtils showError:NSLocalizedString(@"ty_smart_scene_all_device_offline", @"")];
        return;
    }
    
    for (TuyaSmartSceneActionModel *list in model.actions) {
        list.status = TYSceneActionStatusLoading;
    }
    self.actionView = [[TYSceneActionView alloc] init];
    self.actionView.delegate = self;
    [self.actionView showWithTitle:model.name actList:model.actions];
    
    self.smartScene = [TuyaSmartScene sceneWithSceneId:model.sceneId];
    [self.smartScene executeScene:^{
        
    } failure:^(NSError *error) {
        [TPProgressUtils showError:error];
    }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TYSmartSceneTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SmartSceneTableViewCellIdentifier];
    if (cell == nil) {
        cell = [[TYSmartSceneTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SmartSceneTableViewCellIdentifier];
    }
    
    cell.tag = indexPath.row;
    cell.executeButton.tag = indexPath.row;
    [cell.executeButton addTarget:self action:@selector(executeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    TuyaSmartSceneModel *model = self.dataSource[indexPath.row];
    if (model.sceneId == 0) {
        cell.executeButton.enabled = NO;
        cell.executeButton.layer.borderColor = HEXCOLORA(0x8a8e91, 0.4).CGColor;
    } else {
        cell.executeButton.enabled = YES;
        cell.executeButton.layer.borderColor = HEXCOLOR(0x44db5e).CGColor;
    }
    
    cell.topLineView.hidden = YES;
    if (indexPath.row == 0) {
        cell.topLineView.hidden = NO;
    }
    
    cell.bottomLineView.frame = CGRectMake(15, 89.5, APP_SCREEN_WIDTH - 15, 0.5);
    if (indexPath.row == self.dataSource.count - 1) {
        cell.bottomLineView.frame = CGRectMake(0, 89.5, APP_SCREEN_WIDTH, 0.5);
    }
    
    cell.model = model;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
        return;
    }
    
    TYAddSceneViewController *addSceneViewController = [[TYAddSceneViewController alloc] init];
    if (indexPath.row < self.dataSource.count) {
        TuyaSmartSceneModel *model = self.dataSource[indexPath.row];
        addSceneViewController.model = model;
        addSceneViewController.isAdd = NO;
        
        [self presentViewController:[[TPNavigationController alloc] initWithRootViewController:addSceneViewController] animated:YES completion:nil];
    }
}


#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger tag = indexPath.row;
    if (index == 0) {
        TYAddSceneViewController *addSceneViewController = [[TYAddSceneViewController alloc] init];
        addSceneViewController.isAdd = NO;
        TuyaSmartSceneModel *model = self.dataSource[tag];
        addSceneViewController.model = model;
        [self presentViewController:[[TPNavigationController alloc] initWithRootViewController:addSceneViewController] animated:YES completion:nil];
    } else if (index == 1) {
        WEAKSELF_AT
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"ty_smart_scene_del_info_title", nil)
                                       message:NSLocalizedString(@"ty_smart_scene_del_info_cont", nil)
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:@[NSLocalizedString(@"Confirm", nil)]
                                       handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                           
                                           if (buttonIndex == 1) {
                                               [weakSelf_AT showLoadingView];
                                               TuyaSmartSceneModel *model = weakSelf_AT.dataSource[tag];
                                               weakSelf_AT.smartScene = [TuyaSmartScene sceneWithSceneId:model.sceneId];
                                               [weakSelf_AT.smartScene deleteScene:^{
                                                   [weakSelf_AT hideLoadingView];
                                                   [weakSelf_AT.dataSource removeObjectAtIndex:(tag)];
                                                   [weakSelf_AT.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:tag inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                                               } failure:^(NSError *error) {
                                                   [weakSelf_AT hideLoadingView];
                                                   [TPProgressUtils showError:error];
                                               }];
                                           }
                                           
                                       }];
    }
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    return YES;
}

- (void)swipeableTableViewCellDidEndScrolling:(SWTableViewCell *)cell {
    if (!cell.isUtilityButtonsHidden) {
        _swipeCell = cell;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

#pragma mark - TYActionViewDelegate

- (void)TYActionViewDidDismiss {
    [_actionView removeFromSuperview];
    _actionView = nil;
}

#pragma mark - TYSceneHeaderViewDelegate

- (void)TYSceneHeaderViewDidDismiss {
    [TYUserDefault setPreUserDefault:@"1" forKey:kHasCloseEditScene];
    [self.tableView setTableHeaderView:nil];
}


@end
