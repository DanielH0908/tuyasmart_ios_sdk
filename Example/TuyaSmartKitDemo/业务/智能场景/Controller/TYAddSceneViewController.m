//
//  TYAddSceneViewController.m
//  TuyaSmartPublic
//
//  Created by XuChengcheng on 16/7/5.
//  Copyright © 2016年 Tuya. All rights reserved.
//

#import "TYAddSceneViewController.h"
#import "TYTextFieldTableViewCell.h"
#import "TYEditActionTableViewCell.h"
#import "TYSelectDeviceListViewController.h"
#import "TYSelectFeatureViewController.h"
#import "TYEditActionTitleTableViewCell.h"
#import "TYEditActionNoDataTableViewCell.h"
#import "TYSelectConditionViewController.h"

@interface TYAddSceneViewController ()<UITextFieldDelegate, SWTableViewCellDelegate>

@property (nonatomic, strong) TuyaSmartScene *smartScene;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, strong) NSString *textField;
@property (nonatomic, assign) BOOL isChanged;
@property (nonatomic, strong) SWTableViewCell *swipeCell;
@property (nonatomic, strong) NSMutableArray *condationArray;

@end

#define AddSceneTableViewCellIdentifier @"AddSceneTableViewCellIdentifier"

@implementation TYAddSceneViewController

#pragma mark - init & UI

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _smartScene = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initView];
    [self initData];
}

- (void)initView
{
    [self.view addSubview:self.tableView];
    
    WEAKSELF_AT
    [self.tableView bk_whenTapped:^{
        if ([weakSelf_AT.activeTextField isFirstResponder]) {
            [weakSelf_AT.activeTextField resignFirstResponder];
        }
        
        if (weakSelf_AT.swipeCell && !weakSelf_AT.swipeCell.isUtilityButtonsHidden) {
            [weakSelf_AT.swipeCell hideUtilityButtonsAnimated:YES];
        }
    }];
    
    self.tableView.frame = CGRectMake(0, APP_TOP_BAR_HEIGHT, APP_CONTENT_WIDTH, APP_VISIBLE_HEIGHT);
    
    if (!_isAdd && _model.code.length == 0)
    {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH, 88)];
        UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, APP_SCREEN_WIDTH, 48)];
        [deleteBtn setTitle:NSLocalizedString(@"operation_delete", @"") forState:UIControlStateNormal];
        [deleteBtn setTitleColor:HEXCOLOR(0xff3b30) forState:UIControlStateNormal];
        deleteBtn.backgroundColor = [UIColor whiteColor];
        deleteBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        deleteBtn.layer.borderWidth = 0.5;
        deleteBtn.layer.borderColor = LIST_LINE_COLOR.CGColor;
        [deleteBtn addTarget:self action:@selector(deleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:deleteBtn];
        
        self.tableView.tableFooterView = footerView;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTableView:)
                                                 name:kNotificationSmartSceneDPSave
                                               object:nil];
}

- (void)initData
{
    for (TuyaSmartSceneActionModel *model in _model.actions) {
        TuyaSmartDevice *smartDevice = [TuyaSmartDevice deviceWithDeviceId:model.entityId];
        if (smartDevice != nil) {
            [self.dataSource addObject:model];
        }
    }
    [self.tableView reloadData];
}

- (NSString *)titleForCenterItem
{
    return _isAdd ? NSLocalizedString(@"ty_smart_scene_add_new_scene", @"") : NSLocalizedString(@"ty_smart_scene_edit_title", @"");
}

- (NSString *)titleForRightItem
{
    return NSLocalizedString(@"ty_smart_scene_save", @"");
}

//是否显示下拉刷新
- (BOOL)showPullToRefresh {
    return NO;
}
//是否显示上拉刷新
- (BOOL)showInfinite {
    return NO;
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.tableView setEditing:editing animated:animated];
    [self.tableView reloadData];
}

- (TuyaSmartScene *)smartScene
{
    if (_smartScene == nil) {
        if (self.model.sceneId.length > 0)
        {
            _smartScene = [TuyaSmartScene sceneWithSceneId:self.model.sceneId];
        }
    }
    return _smartScene;
}

- (NSMutableArray *)condationArray
{
    if (!_condationArray)
    {
        _condationArray = [NSMutableArray new];
        if (_model.conditions.count > 0)
        {
            for (TuyaSmartSceneConditionModel *model in _model.conditions)
            {
                if (model.entityType == 3)
                {
                    [_condationArray addObject:model];
                }
                else
                {
                    TuyaSmartDevice *smartDevice = [TuyaSmartDevice deviceWithDeviceId:model.entityId];
                    if (smartDevice != nil)
                    {
                        [_condationArray addObject:model];
                    }
                }
            }
        }
    }
    return _condationArray;
}

#pragma mark - Common Events

- (void)refreshTableView:(NSNotification *)notification
{
    _isChanged = YES;
    NSDictionary *modelDic = notification.object;
    NSArray *modelArray = [modelDic objectForKey:@"model"];
    NSInteger selectedItem = [[modelDic objectForKey:@"selectedItem"] tp_toInt];
    BOOL isCondition = [[modelDic objectForKey:@"isCondition"] tp_toBool];
    /*
        设备的联动
        entityId = devId
        entityName = devName
     
        气象的联动：
         entityId = cityId
         entityName = entityName
     */
    
    if (isCondition)//条件
    {
        TuyaSmartSceneDPModel *model = modelArray.firstObject;
        if (model.selectedRow >= 0)
        {
            TuyaSmartSceneConditionModel *conditionModel = [[TuyaSmartSceneConditionModel alloc] initWithSceneDPModel:model];
            if (selectedItem == -1 && self.condationArray.count == 0)
            {
                //新增
                [self.condationArray addObject:conditionModel];
            }
            else
            {
                //修改
                TuyaSmartSceneConditionModel *sourceModel = self.condationArray.firstObject;
                conditionModel.conditionId = sourceModel.conditionId;
                self.condationArray[0] = conditionModel;
            }
        }
        else
        {
            if (selectedItem == -1)
            {
                return;
            }
            else
            {
                [self.condationArray removeAllObjects];
            }
        }
    }
    else//任务
    {
        TuyaSmartSceneActionModel *actModel = [[TuyaSmartSceneActionModel alloc] initWithSceneDPModel:modelArray];
        if (selectedItem == -1)
        {
            //新增
            [self.dataSource addObject:actModel];
        }
        else
        {
            //修改
            TuyaSmartSceneActionModel *sourceModel = self.dataSource[selectedItem];
            actModel.actionId = sourceModel.actionId;
            self.dataSource[selectedItem] = actModel;
        }
    }

    if (isCondition)
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)rightBtnAction
{
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
    }
    
    if ([self.activeTextField isFirstResponder]) {
        [self.activeTextField resignFirstResponder];
    }
    
    [self saveSmartScene];
}

- (void)CancelButtonTap
{
    if (_isChanged) {
        WEAKSELF_AT
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"ty_smart_scene_edit_quit_pop_title", nil)
                                       message:NSLocalizedString(@"ty_smart_scene_edit_quit_pop_info", nil)
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:@[NSLocalizedString(@"ty_smart_scene_edit_quit_pop_title", nil)]
                                       handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                           
                                           if (buttonIndex == 1) {
                                               [weakSelf_AT tp_dismissModalViewController];
                                           }
                                           
                                       }];
    }
    else
    {
        [super CancelButtonTap];
    }
}

- (IBAction)deleteBtnClicked:(id)sender
{
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
    }

    WEAKSELF_AT
    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"ty_smart_scene_del_info_title", nil)
                                   message:NSLocalizedString(@"ty_smart_scene_del_info_cont", nil)
                         cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                         otherButtonTitles:@[NSLocalizedString(@"Confirm", nil)]
                                   handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                       
                                       if (buttonIndex == 1) {
                                           [weakSelf_AT deleteSmartScene];
                                       }
                                       
                                   }];
}

- (IBAction)addSceneBtnClicked:(UIButton *)sender
{
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden)
    {
        [_swipeCell hideUtilityButtonsAnimated:YES];
    }
    
    if ([self.activeTextField isFirstResponder])
    {
        [self.activeTextField resignFirstResponder];
    }

    if (sender.tag == 1)//新增条件
    {
        TYSelectConditionViewController *vc = [TYSelectConditionViewController new];
        vc.selectDevList = [NSMutableArray array];
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    else//新增任务
    {
        TYSelectDeviceListViewController *vc = [[TYSelectDeviceListViewController alloc] init];
        vc.isCondition = NO;
        vc.selectDevList = [NSMutableArray array];
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - API

- (void)saveSmartScene
{
    NSString *title = [_activeTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (title.length == 0 && _model.code.length == 0)
    {
        [TPProgressUtils showError:NSLocalizedString(@"ty_smart_scene_name_enter", @"")];
        return;
    }
    
    //默认场景：有code无id，自定义场景：有id无code
    
    if (self.dataSource.count == 0)
    {
        [TPProgressUtils showError:NSLocalizedString(@"ty_smart_scene_error_add_work", @"")];
        return;
    }
    NSString *sceneName = @"";
    if (self.model.code.length == 0)//添加或编辑自定义场景
    {
        sceneName = self.activeTextField.text;
    }
    else//编辑默认场景
    {
        sceneName = self.model.name;
    }
    
    TuyaSmartSceneConditionModel *condition = nil;
    if (self.condationArray.count > 0)
    {
        condition = self.condationArray[0];
    }
    
    if (self.isAdd)//添加场景
    {
        [self addSmartSceneWithName:sceneName condition:condition];
    }
    else//编辑场景
    {
        [self editSmartSceneWithName:sceneName condition:condition];
    }
}

//创建
- (void)addSmartSceneWithName:(NSString *)name condition:(TuyaSmartSceneConditionModel *)condition
{
    [TPProgressUtils showMessag:NSLocalizedString(@"loading", nil) toView:self.view];
    WEAKSELF_AT
    [TuyaSmartScene addNewScene:name condition:condition actionList:self.dataSource success:^(TuyaSmartSceneModel *sceneModel) {
        [TPProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSmartSceneListUpdate object:nil];
        [weakSelf_AT dismissViewControllerAnimated:YES completion:^{
            
        }];
    } failure:^(NSError *error) {
        [TPProgressUtils hideHUDForView:weakSelf_AT.view animated:YES];
        [TPProgressUtils showError:error];
    }];
}

//编辑
- (void)editSmartSceneWithName:(NSString *)name condition:(TuyaSmartSceneConditionModel *)condition
{
    [TPProgressUtils showMessag:NSLocalizedString(@"loading", nil) toView:self.view];
    WEAKSELF_AT
    [self.smartScene modifyScene:name condition:condition actionList:self.dataSource success:^{
        [TPProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSmartSceneListUpdate object:nil];
        [weakSelf_AT dismissViewControllerAnimated:YES completion:^{
            
        }];
    } failure:^(NSError *error) {
        [TPProgressUtils hideHUDForView:weakSelf_AT.view animated:YES];
        [TPProgressUtils showError:error];
    }];
}

//删除
- (void)deleteSmartScene
{
    WEAKSELF_AT
    [self showLoadingView];
    [self.smartScene deleteScene:^{
        [weakSelf_AT hideLoadingView];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSmartSceneListUpdate object:nil];
        [weakSelf_AT dismissViewControllerAnimated:YES completion:^{
            
        }];
        
    } failure:^(NSError *error) {
        [weakSelf_AT hideLoadingView];
        [TPProgressUtils showError:error];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    } else if (section == 2) {
        if (self.dataSource.count == 0) {
            return 2;
        } else {
            return self.dataSource.count + 1;
        }
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 60;
    } else {
        if (indexPath.row == 0) {
            return 48;
        } else {
            if (indexPath.section == 1) {
                if (self.condationArray.count == 0) {
                    return 76;
                } else {
                    return 64;
                }
            } else {
                if (self.dataSource.count == 0) {
                    return 76;
                } else {
                    return 64;
                }
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSString *cellIdentifier = @"textFieldCell";
        TYTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[TYTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.textField.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName : HEXCOLOR(0x303030)}];
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ty_smart_scene_name_enter", @"") attributes:@{NSForegroundColorAttributeName : HEXCOLOR(0x9b9b9b)}];
        cell.textField.delegate = self;
        if (self.activeTextField == nil) {
            self.activeTextField = cell.textField;
            _textField = nil;
        }
        [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:_model.editIcon] placeholderImage:[UIImage imageNamed:@"ty_scene_custom2"]];
        
        if (!_isAdd) {
            cell.textField.text = _model.name;
        } else {
            cell.textField.text = _textField;
        }
        if (_model.code.length > 0) {
            cell.textField.text = @"";
            cell.textField.placeholder = _model.name;
            cell.textField.enabled = NO;
        }
        return cell;
    } else {
        if (indexPath.row == 0) {
            NSString *cellIdentifier = @"titleSceneCell";
            TYEditActionTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[TYEditActionTitleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            
            cell.addBtn.tag = indexPath.section;
            [cell.addBtn removeTarget:self action:@selector(addSceneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [cell.addBtn addTarget:self action:@selector(addSceneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.addBtn.enabled = YES;
            cell.addImageView.hidden = NO;
            if (indexPath.section == 1) {
                cell.titleLabel.text = NSLocalizedString(@"ty_smart_scene_add_condition", @"");
                if (self.condationArray.count >= 1) {
                    cell.addBtn.enabled = NO;
                    cell.addImageView.hidden = YES;
                }
            } else {
                cell.titleLabel.text = NSLocalizedString(@"ty_smart_scene_add_newwork", @"");
            }
            
            return cell;
            
        } else {
            if ((indexPath.section == 1 && self.condationArray.count == 0) || (indexPath.section == 2 && self.dataSource.count == 0)) {
                NSString *cellIdentifier = @"noDataSceneCell";
                TYEditActionNoDataTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                if (cell == nil) {
                    cell = [[TYEditActionNoDataTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                }
                if (indexPath.section == 1) {
                    cell.titleLabel.text = NSLocalizedString(@"ty_smart_scene_add_notadded", @"");
                } else {
                    cell.titleLabel.text = NSLocalizedString(@"ty_smart_scene_add_notaddedwork", @"");
                }
                
                return cell;
            } else {
                NSString *cellIdentifier = @"SceneCell";
                TYEditActionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                if (cell == nil) {
                    cell = [[TYEditActionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                    cell.delegate = self;
                }
                
                
                cell.offlineLabel.text = NSLocalizedString(@"ty_smart_scene_device_offline", @"");
                
                if (indexPath.section == 1) {
                    TuyaSmartSceneConditionModel *model = self.condationArray[indexPath.row - 1];
                    
                    if (model.entityType == 3) {
                        
                        cell.offlineLabel.hidden = YES;
                        
                        cell.titleLable.text = model.entityName;
                        cell.subTitleLabel.text = model.exprDisplay;
                        cell.iconImageView.image = [UIImage imageNamed:@"smartScene.bundle/ty_device_weather_icon"];
                        
                    } else {
                        
                        TuyaSmartDevice *smartDevice = [TuyaSmartDevice deviceWithDeviceId:model.entityId];
                        
                        cell.offlineLabel.hidden = smartDevice.deviceModel.isOnline;
                        cell.titleLable.text = model.entityName;
                        cell.subTitleLabel.text = model.exprDisplay;
                        [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:smartDevice.deviceModel.iconUrl]];
                        
                    }
                } else {
                    TuyaSmartSceneActionModel *model = self.dataSource[indexPath.row - 1];
                    TuyaSmartDevice *smartDevice = [TuyaSmartDevice deviceWithDeviceId:model.entityId];
                    
                    cell.offlineLabel.hidden = smartDevice.deviceModel.isOnline;
                    cell.titleLable.text = model.entityName;
                    cell.subTitleLabel.text = model.actionDisplay;
                    [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:smartDevice.deviceModel.iconUrl]];
                }
                
                return cell;
            }
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_CONTENT_WIDTH, 20)];
    view.backgroundColor = HEXCOLOR(0xf2f2f2);
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.dataSource.count == 0 && section == 2 && self.condationArray.count == 0) {
        return 0;
    }
    if (section == 1) {
        return 30;
    }
    return 20;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.activeTextField isFirstResponder]) {
        [self.activeTextField resignFirstResponder];
    }
    
    if (_swipeCell && !_swipeCell.isUtilityButtonsHidden) {
        [_swipeCell hideUtilityButtonsAnimated:YES];
        return;
    }

    if (indexPath.row > 0) {
        

        if (indexPath.section == 1 && self.condationArray.count > 0) {
            
            
            TuyaSmartSceneConditionModel *model = self.condationArray[indexPath.row - 1];
            
            if (model.entityType == 3) {
                TYSelectConditionViewController *vc = [[TYSelectConditionViewController alloc] init];
                vc.model = model;
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                TYSelectFeatureViewController *vc = [[TYSelectFeatureViewController alloc] init];
                vc.entityId = model.entityId;
                vc.selectedItem = indexPath.row - 1;
                vc.isCondition = indexPath.section == 1;
                vc.expr = model.expr;

                [self.navigationController pushViewController:vc animated:YES];
            }
        } else if (indexPath.section == 2 && self.dataSource.count > 0){
            TYSelectFeatureViewController *vc = [[TYSelectFeatureViewController alloc] init];
            TuyaSmartSceneActionModel *model = self.dataSource[indexPath.row - 1];
            vc.entityId = model.entityId;
            vc.selectedItem = indexPath.row - 1;
            vc.actDic = model.executorProperty;
            vc.isCondition = indexPath.section == 1;
            
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    self.activeTextField = textField;
    _textField = textField.text;
    _isChanged = YES;
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    if (string.length == 0)
        return YES;
    
    NSInteger strLength = textField.text.length - range.length + string.length;
    if (strLength > 25) {
        return NO;
    }
    
    return YES;
}

#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.section == 2) {
        [self.dataSource removeObjectAtIndex:indexPath.row - 1];
    } else {
        [self.condationArray removeObjectAtIndex:indexPath.row - 1];
    }
    
    [self.tableView reloadData];
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    return YES;
}

- (void)swipeableTableViewCellDidEndScrolling:(SWTableViewCell *)cell {
    NSLog(@"DidEndScrolling - %ld- %d", (long)cell.tag, cell.isUtilityButtonsHidden);
    if (!cell.isUtilityButtonsHidden) {
        _swipeCell = cell;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    NSLog(@"scrollingToState index %ld", (long)cell.tag);
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

@end
