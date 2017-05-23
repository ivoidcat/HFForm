//
//  HFForm.m
//  HFFormTest
//
//  Created by lifenglei on 17/3/15.
//  Copyright © 2017年 lifenglei. All rights reserved.
//

#import "HFForm.h"
#import "HFFormAdaptor.h"
#import "HFFormTitleView.h"
#import "HFFormDefaultTVC.h"
#import "HFFormAlbumTVC.h"
#import "HFFormTitleTVC.h"
#import "HFFormOptionsTVC.h"
#import "HFFormCustomTVC.h"
#import "HFFormSubmitButtonTVC.h"
#import "HFFromDatePickerTVC.h"
#import "HFFormAddSectionButtonTVC.h"
#import "HFFormSwitchTVC.h"
#import "HFFormJumpTVC.h"
#import "HFFormTextViewTVC.h"
#import "HFFormCheckBoxTVC.h"
#import "HFFormTagsTVC.h"

#import "HFFormAlbumModel.h"

#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, HFFormPropertyType) {
    HFFormPropertyTypeLiterals = 0, // 字面量
    HFFormPropertyTypeString,       // NSString
    HFFormPropertyTypeNumber,       // NSNumber/NSDecimalNumber
    HFFormPropertyTypeData,         // NSData
    HFFormPropertyTypeArray,        // NSArray/NSMutableArray
    HFFormPropertyTypeDictionary,   // NSDictionary / NSMutableDictionary
    HFFormPropertyTypeObject,       // NSObject
    HFFormPropertyTypeUnknown
};

@interface HFForm()<HFFormAdaptorDelegate>

@property (nonatomic, strong) NSMutableArray <HFFormSectionModel *>*datas;

@property (nonatomic, strong) NSObject *originalModel;

@end

@implementation HFForm {
    dispatch_semaphore_t _lock;
}

#pragma mark - Public Method
+ (HFFormSectionModel * _Nonnull)section {
    return [[HFFormSectionModel alloc] init];
}

+ (HFFormSectionModel * _Nonnull)sectionWithTitle:(NSString * _Nonnull)title {
    HFFormTitleView *view = [[HFFormTitleView alloc] init];
    [view setTitle:title];
    
    HFFormSectionModel *section = [[HFFormSectionModel alloc] init];
    section.headerView = view;
    section.headerHeight = 30;
    return section;
}
+ (HFFormSectionModel * _Nonnull)sectionWithFooterTitle:(NSString * _Nonnull)title {
    HFFormTitleView *view = [[HFFormTitleView alloc] init];
    [view setTitle:title];
    
    HFFormSectionModel *section = [[HFFormSectionModel alloc] init];
    section.footerView = view;
    section.footerHeight = 30;
    return section;
}

+ (HFFormSectionModel * _Nonnull)sectionWithTitle:(NSString * _Nonnull)title footerTitle:(NSString * _Nonnull)footer {
    HFFormTitleView *header = [[HFFormTitleView alloc] init];
    [header setTitle:title];
    
    HFFormTitleView *foot = [[HFFormTitleView alloc] init];
    [foot setTitle:footer];
    
    HFFormSectionModel *section = [[HFFormSectionModel alloc] init];
    section.headerView = header;
    section.footerView = foot;
    section.headerHeight = 30;
    section.footerHeight = 30;
    return section;
}

+ (HFFormRowModel * _Nonnull)row {
    HFFormRowModel *row = [[HFFormRowModel alloc] init];
    row.type = HFFormRowTypeUnknow;
    return row;
}

+ (HFFormRowModel * _Nonnull)rowWithType:(HFFormRowType)type {
    HFFormRowModel *row = [[HFFormRowModel alloc] init];
    row.type = type;
    switch (type) {
        case HFFormRowTypeDefault:{
            row.height  = 74;
            row.cell    = [HFFormDefaultTVC class];
        }break;
            
        case HFFormRowTypeAlbum:{
            row.cell    = [HFFormAlbumTVC class];
        }break;
            
        case HFFormRowTypeTitle:{
            row.height  = 44;
            row.cell    = [HFFormTitleTVC class];
        }break;
            
        case HFFormRowTypeOptions: {
            row.height  = 74;
            row.cell    = [HFFormOptionsTVC class];
        }break;
            
        case HFFormRowTypeDatePicker:{
            row.height  = 74;
            row.cell    = [HFFromDatePickerTVC class];
        }break;
            
        case HFFormRowTypeSwitch:{
            row.height  = 48;
            row.cell    = [HFFormSwitchTVC class];
        }break;
            
        case HFFormRowTypeText: {
            row.cell    = [HFFormTextViewTVC class];
        }break;
            
        case HFFormRowTypeJump: {
            row.height  = 74;
            row.cell    = [HFFormJumpTVC class];
        }break;
            
        case HFFormRowTypeSubmit:{
            row.height  = 100;
            row.cell    = [HFFormSubmitButtonTVC class];
        }break;
            
        case HFFormRowTypeCheckBox: {
            row.cell    = [HFFormCheckBoxTVC class];
        }break;
            
        case HFFormRowTypeTags: {
            row.cell    = [HFFormTagsTVC class];
        }break;
            
        case HFFormRowTypeCustom: {
            row.cell = [HFFormCustomTVC class];
        }break;
            
        case HFFormRowTypeAddSection: {
            row.height  = 80;
            row.cell    = [HFFormAddSectionButtonTVC class];
        }break;
            
        default:
            break;
    }
    return row;
}

- (void)appendSection:(HFFormSectionModel * _Nonnull)section {
    for (HFFormRowModel *row in section.rows) {
        [self _reConfigRow:row];
    }
    [self.datas addObject:section];
}

- (void)appendSection:(HFFormSectionModel * _Nonnull)section atIndex:(NSUInteger)index {
    NSAssert(index < self.datas.count, @"添加section的时候越界了");
    
    for (HFFormRowModel *row in section.rows) {
        [self _reConfigRow:row];
    }
    
    [self.datas insertObject:section atIndex:index];
    
    [self.adpator insertSection:[NSIndexSet indexSetWithIndex:index]];
}

- (void)appendRow:(HFFormRowModel * _Nonnull)row {
    NSAssert(self.datas.count <= 1, @"请使用appendRow:inSection方法，本方法只适用于一个section的情况");
    
    HFFormSectionModel *section = self.datas.count == 1 ? self.datas.firstObject : [self.class section];
    [section appendRow:row];
    [self _reConfigRow:row];
    if (self.datas.count == 0) [self.datas addObject:section];
}

- (void)appendRows:(NSArray <HFFormRowModel *> *_Nonnull)rows below:(HFFormRowModel *_Nonnull)lastRow {
    NSAssert(self.datas.count >= 1, @"还没有初始化一个section");
    
    NSMutableArray *indexs = @[].mutableCopy;
    HFFormSectionModel *section = self.datas.firstObject;
    for (NSInteger idx = 0; idx < rows.count; idx++) {
        HFFormRowModel *row = rows[idx];
        [self _reConfigRow:row];
        NSInteger pos = [[section rows] indexOfObject:lastRow] + 1 + idx;
        [section appendRow:row adIndex:pos];
        [indexs addObject: [NSIndexPath indexPathForRow:pos inSection:0]];
    }
    
    [self.adpator insertRows:indexs];
}

- (void)appendRows:(NSArray <HFFormRowModel *> * _Nonnull)rows inSection:(HFFormSectionModel * _Nonnull)section {
    NSMutableArray *indexs = @[].mutableCopy;
    for (NSInteger idx = 0; idx < rows.count; idx++) {
        HFFormRowModel *row = rows[idx];
        [self _reConfigRow:row];
        [section appendRow:row];
        
        [indexs addObject:[NSIndexPath indexPathForRow:section.rows.count - 1 inSection:[self _indexOfSection:section]]];
    }
    [self.adpator insertRows:indexs];
}

- (void)appendRows:(NSArray <HFFormRowModel *> * _Nonnull)rows inSection:(HFFormSectionModel * _Nonnull)section rowAtSection:(NSUInteger)index {
    NSMutableArray *indexs = @[].mutableCopy;
    for (NSInteger idx = 0; idx < rows.count; idx++) {
        HFFormRowModel *row = rows[idx];
        [self _reConfigRow:row];
        [section appendRow:row adIndex:index + idx];
        
        [indexs addObject:[NSIndexPath indexPathForRow:index + idx inSection:[self _indexOfSection:section]]];
    }
    [self.adpator insertRows:indexs];
}

- (HFFormSectionModel * _Nonnull)sectionOfIndex:(NSUInteger)index {
    NSAssert(index < self.datas.count, @"读取section的时候越界了");
    return self.datas[index];
}

- (HFFormRowModel * _Nonnull)rowInSection:(HFFormSectionModel * _Nonnull)section ofIndex:(NSUInteger)index {
    NSAssert(index < section.rows.count, @"读取row的时候越界了");
    return section.rows[index];
}

- (HFFormSectionModel *)obtainSectionWithKey:(NSString * _Nonnull)key {
    HFFormSectionModel *section;
    for (HFFormSectionModel *model in self.datas) {
        if ([section.key isEqualToString:key]) {
            section = model;
            break;
        }
    }
    return section;
}

- (NSArray *)obtainRowWithKey:(NSString * _Nonnull)key {
    __block NSMutableArray *array = @[].mutableCopy;
    [self.datas enumerateObjectsUsingBlock:^(HFFormSectionModel * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        for (HFFormRowModel *model in section.rows) {
            if ([model.key isEqualToString:key]) {
                [array addObject:model];
            }
            if (model.subRows.count > 0) {
                for (HFFormRowModel *subRow in model.subRows) {
                    if ([subRow.key isEqualToString:key]) {
                        [array addObject:subRow];
                    }
                }
            }
        }
    }];
    return array;
}

- (NSArray * _Nullable)obtainAllRows {
    return [self _obtainAllRows];
}

- (void)deleteSections:(NSArray <HFFormSectionModel *> * _Nonnull)sections {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (HFFormSectionModel *section in sections) {
        NSInteger idx = [self _indexOfSection:section];
        [indexSet addIndexes:[NSIndexSet indexSetWithIndex:idx]];
        [self.datas removeObject:section];
    }
    [self.adpator deleteSection:indexSet];
}

- (void)deleteSectionWithKey:(NSString * _Nonnull)key {
    HFFormSectionModel *section = [self obtainSectionWithKey:key];
    if (section) {
        [self.adpator deleteSection:[NSIndexSet indexSetWithIndex:[self _indexOfSection:section]]];
        [self.datas removeObject:section];
    }
}

- (void)deleteSectionWithIndex:(NSUInteger)index {
    NSAssert(index < self.datas.count, @"要删除的组越界了");
    
    [self.adpator deleteSection:[NSIndexSet indexSetWithIndex:index]];
    [self.datas removeObjectAtIndex:index];
}

- (void)deleteRows:(NSArray <HFFormRowModel *> * _Nonnull)rows {
    NSMutableArray *indexs = @[].mutableCopy;
    for (NSInteger idx = 0; idx < rows.count; idx++) {
        HFFormRowModel *row = rows[idx];
        for (HFFormSectionModel *section in self.datas) {
            if ([section.rows containsObject:row]) {
                [indexs addObject:[NSIndexPath indexPathForRow:[self _indexOfRow:row inSection:section] inSection:[self _indexOfSection:section]]];
                [section deleteRow:row];
            }
        }
    }
    if(indexs.count > 0) [self.adpator deleteRows:indexs];
}

- (void)deleteRows:(NSArray <HFFormRowModel *> * _Nonnull)rows inSection:(HFFormSectionModel * _Nonnull)section {
    // 检查是否存在这个row
    if(![section.rows containsObject:rows.firstObject]) return;
    NSMutableArray *indexs = @[].mutableCopy;
    for (NSInteger idx = 0; idx < rows.count; idx++) {
        HFFormRowModel *row = rows[idx];
        
        [indexs addObject:[NSIndexPath indexPathForRow:[self _indexOfRow:row inSection:section] + idx inSection:[self _indexOfSection:section]]];
        
        [section deleteRow:row];
    }
    if(indexs.count > 0) [self.adpator deleteRows:indexs];
}

- (void)deleRowWithKey:(NSString * _Nonnull)key {
    WEAK_SELF;
    [self.datas enumerateObjectsUsingBlock:^(HFFormSectionModel * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        STRONG_SELF;
        for (HFFormRowModel *model in section.rows) {
            if ([model.key isEqualToString:key]) {
                [section deleteRow:model];
                [self.adpator deleteRow:[self _obtainIndexWithRow:model]];
                break;
                *stop = YES;
            }
        }
    }];
}

- (NSUInteger)obtainSectionCount {
    return self.datas.count;
}

- (BOOL)containRow:(HFFormRowModel * _Nonnull)row {
    BOOL contain = NO;
    for (HFFormSectionModel *section in self.datas) {
        for (HFFormRowModel *aRow in section.rows) {
            if (row == aRow) {
                contain = YES;
                break;
            }
        }
        if(contain) break;
    }
    return contain;
}

- (void)reloadData {
    if (self.datas.count == 0) return;
    self.adpator.datas = self.datas;
}

- (void)reloadRow:(HFFormRowModel * _Nonnull)row {
    [self.adpator reloadRow:[self _obtainIndexWithRow:row]];
}

- (void)reloadRows:(NSArray <HFFormRowModel *> * _Nonnull)rows {
    NSMutableArray *indexPaths = @[].mutableCopy;
    for (HFFormRowModel *row in rows) {
        NSIndexPath *indexPath = [self _obtainIndexWithRow:row];
        if(indexPath) [indexPaths addObject:indexPath];
    }
    if(indexPaths.count > 0) [self.adpator reloadRows:indexPaths];
}

- (void)reloadHeight {
    [self.adpator reloadHeight];
}

- (NSDictionary * _Nullable)exportDataToDictionary {
    NSMutableDictionary *params = @{}.mutableCopy;
    NSArray *ignorekeys = nil;
    if ([self.delegate respondsToSelector:@selector(ignoreKeys)]) {
        ignorekeys = [self.delegate ignoreKeys];
    }
    for (HFFormSectionModel *section in self.datas) {
        for (HFFormRowModel *row in section.rows) {
            if (row.subRows.count > 0) {
                for (HFFormRowModel *subRow in row.subRows) {
                    if(subRow.key && subRow.key.length > 0){
                        if (ignorekeys && [ignorekeys containsObject:subRow.key]) {
                            continue;
                        }
                        params[subRow.key] = subRow.value;
                    }
                }
            }else{
                if(row.key && row.key.length > 0) {
                    if (ignorekeys && [ignorekeys containsObject:row.key]) {
                        continue;
                    }
                    if (row.type == HFFormRowTypeAlbum) {
                        params[row.key] = [(HFFormAlbumModel *)row.value postDataFormat];
                    }else{
                        params[row.key] = row.value;
                    }
                }
            }
        }
    }
    return params;
}

- (id _Nullable)exportDataToObject:(id _Nonnull)object {
    if ([object isKindOfClass:[NSObject class]]) {
        unsigned int count;
        NSObject *obj = (NSObject *)object;
        objc_property_t *properties = class_copyPropertyList([obj class], &count);
        for (NSInteger idx = 0; idx < count; idx++) {
            objc_property_t property  = properties[idx];
            NSString *name = [NSString stringWithUTF8String:property_getName(property)];
            id value = [obj valueForKey:name];
            NSArray *rows = [self _obtainAllRows];
            for (HFFormRowModel *row in rows) {
                if ([row.key isEqualToString:name]) {
                    if(row.value) {
                        if (row.type == HFFormRowTypeAlbum) {
                            if ([self.delegate respondsToSelector:@selector(replaceProperty)]) {
                                NSDictionary *dict = [self.delegate replaceProperty];
                                NSString *replaceKey = dict[name];
                                if (replaceKey) [object setValue:row.value forKey:replaceKey];
                                NSString *postValue = [(HFFormAlbumModel *)row.value postDataFormat];
                                if(postValue) {
                                    [object setValue:postValue forKey:name];
                                    row.content = postValue;
                                }
                            }
                        }else{
                            HFFormPropertyType type = [self _getTypeWithString:[NSString stringWithUTF8String:property_getAttributes(property)]];
                            switch (type) {
                                case HFFormPropertyTypeString:{
                                    if ([row.value isKindOfClass:[NSString class]]) {
                                        [object setValue:row.value forKey:name];
                                    }else if ([row.value isKindOfClass:[NSNumber class]]) {
                                        [object setValue:[NSString stringWithFormat:@"%@",row.value] forKey:name];
                                    }
                                }break;
                                    
                                case HFFormPropertyTypeNumber:{
                                    if ([row.value isKindOfClass:[NSNumber class]]) {
                                        [object setValue:row.value forKey:name];
                                    }else if ([row.value isKindOfClass:[NSString class]]) {
                                        [object setValue:@([row.value doubleValue]) forKey:name];
                                    }
                                }break;
                                    
                                default:
                                    [object setValue:row.value forKey:name];
                                    break;
                            }
                            
                        }
                    }else if(!row.value && value) {
                        value = nil;
                    }
                    break;
                }
            }
        }
        free(properties);
        return object;
    }
    return nil;
}

- (NSDictionary * _Nullable)dictFromModel:(id _Nonnull)model {
    if ([model isKindOfClass:[NSObject class]]) {
        NSMutableDictionary *dict = @{}.mutableCopy;
        NSMutableArray *array = @[].mutableCopy;
        unsigned int count;
        NSObject *obj = (NSObject *)model;
        objc_property_t *properties = class_copyPropertyList([obj class], &count);
        for (NSInteger idx = 0; idx < count; idx++) {
            objc_property_t property  = properties[idx];
            NSString *name = [NSString stringWithUTF8String:property_getName(property)];
            if ([self.delegate respondsToSelector:@selector(ignoreKeys)]) {
                if ([[self.delegate ignoreKeys] containsObject:name]) {
                    continue;
                }
            }
            id value = [obj valueForKey:name];
            dict[name] = value;
            
            if ([self.delegate respondsToSelector:@selector(replaceProperty)]) {
                NSString *key = [self.delegate replaceProperty][name];
                if(key) [array addObject:key];
            }
        }
        free(properties);
        
        // 不需要key的不需要转
        if (array.count > 0) {
            [array enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                dict[obj] = nil;
            }];
        }
        return dict;
    }
    return nil;
}

- (void)importData:(id _Nonnull)data {
    if (!self.datas || self.datas.count == 0) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([data isKindOfClass:[NSObject class]]) {
            unsigned int count;
            NSObject *obj = (NSObject *)data;
            self.originalModel = obj;
            objc_property_t *properties = class_copyPropertyList([obj class], &count);
            for (NSInteger idx = 0; idx < count; idx++) {
                objc_property_t property  = properties[idx];
                NSString *name = [NSString stringWithUTF8String:property_getName(property)];
                id value = [obj valueForKey:name];
                NSArray *rows = [self _obtainAllRows];
                for (HFFormRowModel *row in rows) {
                    NSString *key = row.key;
                    if ([key isEqualToString:name]) {
                        if (row.type == HFFormRowTypeAlbum) {
                            id replaceValue = nil;
                            if ([self.delegate respondsToSelector:@selector(replaceProperty)]) {
                                NSDictionary *dict = [self.delegate replaceProperty];
                                replaceValue = [obj valueForKey:dict[key]];
                            }else{
                                replaceValue = value;
                            }
                            row.value = replaceValue;
                            row.content = [obj valueForKey:key];
                        }else if (row.type == HFFormRowTypeDefault || row.type == HFFormRowTypeText) {
                            if (value) {
                                if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                                    row.value = value;
                                }else if(![value isKindOfClass:[NSString class]]){
                                    if ([value isKindOfClass:[NSNumber class]]) {
                                        if (![value isEqualToNumber:@0]) {
                                            row.value = [NSString stringWithFormat:@"%@",value];
                                        }
                                    }else{
                                        row.value = [NSString stringWithFormat:@"%@",value];
                                    }
                                    
                                }
                            }
                        }else{
                            if ([value isKindOfClass:[NSString class]]) {
                                if ([value length] > 0) {
                                    row.value = value;
                                }
                            }else{
                                row.value = value;
                            }
                        }
                        break;
                    }
                }
            }
            free(properties);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    });
}

- (BOOL)checkEditedWithModel:(id _Nullable)model {
    if (!model) {
        return [self _checkIsEdited];
    }else{
        return [self _checkIsEditedWithModel:model];
    }
}

- (BOOL)checkRowFinished {
    BOOL finish = YES;
    for (HFFormSectionModel *section in self.datas) {
        // 检验是否要必填的
        for (HFFormRowModel *row in section.rows) {
            // 本身就是必填项，就校验有没有填值
            if (row.neccesary) {
                // 多选项
                if (row.subRows && row.subRows.count > 0) {
                    for (HFFormRowModel *subRow in row.subRows) {
                        if (subRow.neccesary) {
                            if (!subRow.value) {
                                finish = NO;
                                
                                if(row.invalidHandler) row.invalidHandler();
                                [HFFormHelper showNotice:[NSString stringWithFormat:@"请选择%@", row.title]];
                                
                                break;
                            }
                        }
                    }
                }
                if (!finish) break;
                
                if (!row.value) {
                    if(row.invalidHandler) row.invalidHandler();
                    if (row.type == HFFormRowTypeDefault || row.type == HFFormRowTypeText) {
                        [HFFormHelper showNotice:[NSString stringWithFormat:@"请输入%@", row.title]];
                    }else{
                        [HFFormHelper showNotice:[NSString stringWithFormat:@"请选择%@", row.title]];
                    }
                    
                    finish = NO;
                    break;
                }
                // 多选项的
            }else if (row.subRows && row.subRows.count > 0) {
                for (HFFormRowModel *subRow in row.subRows) {
                    if (subRow.neccesary) {
                        if (!subRow.value) {
                            finish = NO;
                            
                            if(row.invalidHandler) row.invalidHandler();
                            [HFFormHelper showNotice:[NSString stringWithFormat:@"请选择%@", row.title]];
                            
                            break;
                        }
                    }
                }
                
                if(!finish) break;
            }
            
            if (finish && row.value) {
                // 检验是否有验证条件，如果有则校验
                if (row.checkHandler) {
                    NSError *error = row.checkHandler(row.value);
                    if (error) {
                        if(row.invalidHandler) row.invalidHandler();
                        [HFFormHelper showNotice:error.localizedDescription];
                        finish = NO;
                        break;
                    }
                }
            }
        }
    }
    
    return finish;
}

#pragma mark - HFFormAdaptorDelegate
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath rowModel:(HFFormRowModel *)row tableViewCell:(UITableViewCell * _Nullable)cell {
    if([self.delegate respondsToSelector:@selector(form:didSelectRowAtIndexPath:rowModel:tableViewCell:)]) {
        [self.delegate form:self didSelectRowAtIndexPath:indexPath rowModel:row tableViewCell:cell];
    }
}

- (void)setRowAtIndexPath:(NSIndexPath *)indexPath rowModel:(HFFormRowModel *)row tableViewCell:(UITableViewCell *)cell {
    if ([self.delegate respondsToSelector:@selector(form:setRowAtIndexPath:rowModel:tableViewCell:)]) {
        [self.delegate form:self setRowAtIndexPath:indexPath rowModel:row tableViewCell:cell];
    }
}

#pragma mark - Initialize
- (instancetype)init {
    if (self = [super init]) {
        self.adpator = [[HFFormAdaptor alloc] init];
        self.adpator.delegate = self;
        self.datas = @[].mutableCopy;
        
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Private Method
- (NSInteger)_indexOfSection:(HFFormSectionModel * _Nonnull)section {
    return [self.datas indexOfObject:section];
}

- (NSInteger)_indexOfRow:(HFFormRowModel *)row inSection:(HFFormSectionModel * _Nonnull)section {
    NSAssert([section.rows containsObject:row], @"section里不包含row");
    return [section.rows indexOfObject:row];
}

- (NSIndexPath *)_obtainIndexWithRow:(HFFormRowModel * _Nonnull)row {
    __block NSIndexPath *indexPath = nil;
    [self.datas enumerateObjectsUsingBlock:^(HFFormSectionModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.rows containsObject:row]) {
            indexPath = [NSIndexPath indexPathForRow:[model.rows indexOfObject:row] inSection:idx];
        }
    }];
    return indexPath;
}

- (void)_reConfigRow:(HFFormRowModel *)row {
    __weak HFFormRowModel *tmpRow = row;
    __weak typeof(self)weakSelf = self;
    row.reloadHandler = ^(HFFormRefreshType type){
        __strong typeof(weakSelf)self = weakSelf;
        if (type == HFFormRefreshTypeAll) {
            [self reloadData];
        }else if (type == HFFormRefreshTypeRow) {
            [self reloadRow:tmpRow];
        }else if (type == HFFormRefreshTypeHeight) {
            [self reloadHeight];
        }
    };
}

- (NSArray *)_obtainAllRows {
    NSMutableArray *rows = @[].mutableCopy;
    for (HFFormSectionModel *section in self.datas) {
        for (HFFormRowModel *row in section.rows) {
            [rows addObject:row];
            for (HFFormRowModel *subRow in row.subRows) {
                [rows addObject:subRow];
            }
        }
    }
    return rows;
}

- (BOOL)_checkIsEdited {
    BOOL _change = NO;
    for (HFFormSectionModel *section in self.datas) {
        for (HFFormRowModel *row in section.rows) {
            if (row.value) {
                if([row.value isKindOfClass:[NSString class]] && [row.value length] == 0) {
                    continue;
                }else{
                    _change = YES;
                    break;
                }
            }
            if (row.subRows.count > 0) {
                for (HFFormRowModel *subRow in row.subRows) {
                    if (subRow.value) {
                        if([subRow.value isKindOfClass:[NSString class]] && [subRow.value length] == 0) {
                            continue;
                        }else{
                            _change = YES;
                            break;
                        }
                    }
                }
                if (_change) break;
            }
        }
        if (_change) break;
    }
    return  _change;
}

- (BOOL)_checkIsEditedWithModel:(id)model {
    BOOL change = NO;
    if ([model isKindOfClass:[NSObject class]]) {
        NSObject *aModel = (NSObject *)model;
        NSArray *rows = [self _obtainAllRows];
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList([aModel class], &outCount);
        for (HFFormRowModel *row in rows) {
            if (row.value) {
                for (NSInteger i = 0; i < outCount; i++) {
                    objc_property_t property = properties[i];
                    NSString *propertyType = [NSString stringWithUTF8String:property_getAttributes(property)];
                    NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
                    id propertyValue = [aModel valueForKey:propertyName];
                    if ([row.key isEqualToString:propertyName]) {
                        switch ([self _getTypeWithString:propertyType]) {
                            case HFFormPropertyTypeLiterals:{
                                change = !(propertyValue == row.value);
                            }break;
                                
                            case HFFormPropertyTypeString: {
                                if ([row.value isKindOfClass:[NSString class]]) {
                                    change = ![[NSString stringWithFormat:@"%@", propertyValue] isEqualToString:(NSString *)row.value];
                                }else if (row.type == HFFormRowTypeAlbum) {
                                    if(propertyValue && row.content) change = ![(NSString *)propertyValue isEqualToString:row.content];
                                }
                                
                            }break;
                                
                            case HFFormPropertyTypeNumber:{
                                NSNumber *value = nil;
                                if ([row.value isKindOfClass:[NSString class]]) {
                                    value = @([row.value doubleValue]);
                                }else if([row.value isKindOfClass:[NSNumber class]]) {
                                    value = row.value;
                                }
                                if(value) change = ![(NSNumber *)propertyValue isEqualToNumber:value];
                            }break;
                                
                            case HFFormPropertyTypeData:{
                                change = ![(NSData *)propertyValue isEqualToData:(NSData *)row.value];
                            }break;
                                
                            case HFFormPropertyTypeArray:{
                                change = ![(NSArray *)propertyValue isEqualToArray:(NSArray *)row.value];
                            }break;
                                
                            case HFFormPropertyTypeDictionary:{
                                change = ![(NSDictionary *)propertyValue isEqualToDictionary:(NSDictionary *)row.value];
                            }break;
                                
                            case HFFormPropertyTypeObject: {
                                change = ![propertyValue isEqual:row.value];
                            }
                                
                            default:
                                break;
                        }
                    }
                    if (change) break;
                }
            }
            if (change) break;
        }
        free(properties);
    }
    return change;
}

- (BOOL)_checkModel:(id)oldModel isEqual:(id)newModel {
    BOOL change = NO;
    if ([oldModel isKindOfClass:[NSObject class]] && [newModel isKindOfClass:[NSObject class]]) {
        unsigned int oldOutCount, i, newOutCount;
        objc_property_t *oldProperties = class_copyPropertyList([oldModel class], &oldOutCount);
        objc_property_t *newProperties = class_copyPropertyList([newModel class], &newOutCount);
        for (i = 0; i < oldOutCount; i++)
        {
            objc_property_t oldProperty = oldProperties[i];
            NSString *oldPropertyType = [NSString stringWithUTF8String:property_getAttributes(oldProperty)];
            NSString *oldPropertyName = [NSString stringWithUTF8String:property_getName(oldProperty)];
            id oldPropertyValue = [oldModel  valueForKey:(NSString *)oldPropertyName];
            
            objc_property_t newProperty = newProperties[i];
            NSString *newPropertyType = [NSString stringWithUTF8String:property_getAttributes(newProperty)];
            NSString *newPropertyName = [NSString stringWithUTF8String:property_getName(newProperty)];
            id newPropertyValue = [newModel valueForKey:(NSString *)newPropertyName];
            
            if ([oldPropertyType isEqualToString:newPropertyType]) {
                switch ([self _getTypeWithString:oldPropertyType]) {
                    case HFFormPropertyTypeLiterals:{
                        change = !(oldPropertyValue == newPropertyValue);
                    }break;
                        
                    case HFFormPropertyTypeString: {
                        change = ![(NSString *)oldPropertyValue isEqualToString:(NSString *)newPropertyValue];
                    }break;
                        
                    case HFFormPropertyTypeNumber:{
                        change = ![(NSNumber *)oldPropertyValue isEqualToNumber:(NSNumber *)newPropertyValue];
                    }break;
                        
                    case HFFormPropertyTypeData:{
                        change = ![(NSData *)oldPropertyValue isEqualToData:(NSData *)newPropertyValue];
                    }break;
                        
                    case HFFormPropertyTypeArray:{
                        change = ![(NSArray *)oldPropertyValue isEqualToArray:(NSArray *)newPropertyValue];
                    }break;
                        
                    case HFFormPropertyTypeDictionary:{
                        change = ![(NSDictionary *)oldPropertyValue isEqualToDictionary:(NSDictionary *)newPropertyValue];
                    }break;
                        
                    case HFFormPropertyTypeObject: {
                        change = ![oldPropertyValue isEqual:newPropertyValue];
                    }
                        
                    default:
                        break;
                }
            }
        }
        free(oldProperties);
        free(newProperties);
    }
    return change;
}

- (HFFormPropertyType)_getTypeWithString:(NSString *)type {
    HFFormPropertyType pType;
    switch (type.UTF8String[0]) {
        case 'T':
            type = [self type:type getMatchesForRegex:@"\"[\u4e00-\u9fa5a-zA-Z0-9]*\""].firstObject;
            type = [type stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            if ([type isEqualToString:@"NSString"] || [type isEqualToString:@"NSMutableString"]) {
                pType = HFFormPropertyTypeString;
            }else if([type isEqualToString:@"NSNumber"] || [type isEqualToString:@"NSDecimalNumber"]) {
                pType = HFFormPropertyTypeNumber;
            }else if([type isEqualToString:@"NSData"] || [type isEqualToString:@"NSMutableData"]) {
                pType = HFFormPropertyTypeData;
            }else if ([type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSMutableArray"]) {
                pType = HFFormPropertyTypeArray;
            }else if ([type isEqualToString:@"NSDictionary"] || [type isEqualToString:@"NSMutableDictionary"]) {
                pType = HFFormPropertyTypeDictionary;
            }else if ([NSClassFromString(type) isSubclassOfClass:[NSObject class]]) {
                pType = HFFormPropertyTypeObject;
            }else if ([type isEqualToString:@"int"] || [type isEqualToString:@"long"] || [type isEqualToString:@"float"] || [type isEqualToString:@"double"] || [type isEqualToString:@"BOOL"]) {
                pType = HFFormPropertyTypeLiterals;
            }else{
                pType = HFFormPropertyTypeUnknown;
            }
            break;
            
        default:
            pType = HFFormPropertyTypeUnknown;
            break;
    }
    return pType;
}

- (NSArray *)type:(NSString *)type getMatchesForRegex:(NSString *)regex{
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:1];
    
    NSError * error;
    NSRegularExpression * expression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray * matches                = [expression matchesInString:type options:0 range:NSMakeRange(0, type.length)];
    for (int i = 0; i < matches.count; i++) {
        NSTextCheckingResult * result = [matches objectAtIndex:i];
        
        for (int j = 0; j < result.numberOfRanges; j++) {
            NSRange range = [result rangeAtIndex:j];
            if (range.location == NSNotFound) {
                continue;
            }
            NSString * string = [type substringWithRange:range];
            [array addObject:string];
        }
    }
    
    return array;
}

@end
