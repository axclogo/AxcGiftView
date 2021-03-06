//
//  AxcGiftView.m
//  GiftView
//
//  Created by 众诚云金 on 2020/9/8.
//  Copyright © 2020 AxcLogo. All rights reserved.
//

#import "AxcGiftView.h"

@interface AxcGiftView ()<
UITableViewDelegate,
UITableViewDataSource,
AxcGiftOperationCellDelegate
>
// 展示列表
@property(nonatomic,strong)UITableView *tableView;
// 操作缓存池
@property (nonatomic,strong) NSMutableArray <NSDictionary *>*operationCache;
@end

@implementation AxcGiftView
- (instancetype)init{
    if (self == [super init]) [self initial];
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) [self initial];
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder{
    if (self == [super initWithCoder:coder]) [self initial];
    return self;
}
- (void)initial{    // 初始化
    self.showMaxGiftViewCount = 3;
    self.showMaxGiftViewHeight = 60.f;
    self.arrangementType = AxcGiftViewArrangementTypeTopToBottom;
    self.giftShowTime = 5.f;
    self.giftEnterAnimationTime =
    self.giftQuitAnimationTime  = 0.5;
    self.giftEnterAnimationOptions =
    self.giftQuitAnimationOptions = UIViewAnimationOptionCurveEaseInOut;
    self.enterAnimationStyle = AxcGiftOperationAnimationStyleLeft;
    self.quitAnimationStyle = AxcGiftOperationAnimationStyleLeft;
    self.is_gradually = YES;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
    [self reloadData];
}


- (void)insertGift:(id )gift identifier:(NSString *)identifier{
    // 取出一个空闲的cell
    AxcGiftOperationCell *operationCell = [self operationCellWithIdentifier:identifier];
    if (operationCell) {    // 当前有礼物在展示
        [operationCell resetTimer]; // 重置计时器
        // 回调连击事件
        // 获取连击数model
        id comboGift = [self.dataSource axc_giftView:self comboCountWithGifts:@[operationCell.gift,gift]];
        if ([self.delegate respondsToSelector:@selector(axc_giftView:comboWithGift:showView:)]) {  // 有实现
            // 更改连击视图
            [self.delegate axc_giftView:self comboWithGift:comboGift showView:operationCell.giftAnimationView];
        }
    }else{  // 没有展示，需要添加到cell的背景视图
        operationCell = [self emptyOperationCellWithType:self.arrangementType];  // 获取一个空视图承载cell
        if (operationCell) {    // 如果有空位
            // 向代理索要view视图
            operationCell.giftAnimationView = [self.dataSource axc_giftView:self giftViewWithGift:gift identifier:identifier];
            // 向代理索要已设置的参数
            [self delegateSetting:operationCell gift:gift identifier:identifier];
            
            operationCell.showTime = self.giftShowTime;     // 展示时间
            operationCell.is_gradually = self.is_gradually; // 渐变
            // 出入场枚举
            operationCell.enterAnimationStyle = self.enterAnimationStyle;
            operationCell.quitAnimationStyle = self.quitAnimationStyle;
            // 出入场动画时间
            operationCell.giftEnterAnimationTime = self.giftEnterAnimationTime;
            operationCell.giftQuitAnimationTime = self.giftQuitAnimationTime;
            // 出入场动画延迟
            operationCell.giftEnterAnimationDelay = self.giftEnterAnimationDelay;
            operationCell.giftQuitAnimationDelay = self.giftQuitAnimationDelay;
            // 礼物相关
            operationCell.identifier = identifier;
            operationCell.gift = gift;
            // 回调即将出现
            if ([self.delegate respondsToSelector:@selector(axc_giftView:giftWillAppearWithShowView:gift:identifier:)]) {
                [self.delegate axc_giftView:self giftWillAppearWithShowView:operationCell.giftAnimationView gift:gift
                                 identifier:identifier];
            }
            [operationCell appearAnimation];    // 开始展示
        }else{  // 没有足够的空位，放入缓存
            // 判断是否在缓存中有重复的
            id existGift = [self containsOperationCacheIdentifier:identifier];
            if (existGift) { // 有重复的
                // 获取连击数
                id comboGift = [self.dataSource axc_giftView:self comboCountWithGifts:@[existGift,gift]];
                // 替换缓存
                [self replaceOperationCache:comboGift identifier:identifier];
            }else{  // 新增的礼物
                // 添加进缓存
                [self.operationCache addObject:@{identifier:gift}];
            }
        }
    }
}
#pragma mark - 封装
- (void)delegateSetting:(AxcGiftOperationCell *)operationCell gift:(id )gift identifier:(NSString *)identifier{
    // 展示时间
    if ([self.delegate respondsToSelector:@selector(axc_giftView:showTimeWithGift:identifier:)]) {
        self.giftShowTime = [self.delegate axc_giftView:self showTimeWithGift:operationCell.giftAnimationView
                                             identifier:identifier];
    }
    // 渐入渐出
    if ([self.delegate respondsToSelector:@selector(axc_giftView:graduallyWithGift:identifier:)]) {
        self.is_gradually = [self.delegate axc_giftView:self graduallyWithGift:gift identifier:identifier];
    }
    // 动画时间
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftAnimationTimeWithState:gift:identifier:)]) {
        // 入场动画时间
        self.giftEnterAnimationTime = [self.delegate axc_giftView:self
                                       giftAnimationTimeWithState:AxcGiftOperationAnimationStateEnter
                                                             gift:gift identifier:identifier];
        // 出场动画时间
        self.giftQuitAnimationTime = [self.delegate axc_giftView:self
                                      giftAnimationTimeWithState:AxcGiftOperationAnimationStateQuit
                                                            gift:gift identifier:identifier];
    }
    // 动画时间曲线
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftAnimationOptionsWithState:gift:identifier:)]) {
        // 入场动画时间曲线
        self.giftEnterAnimationOptions = [self.delegate axc_giftView:self
                                       giftAnimationOptionsWithState:AxcGiftOperationAnimationStateEnter
                                                                gift:gift identifier:identifier];
        // 出场动画时间曲线
        self.giftQuitAnimationOptions = [self.delegate axc_giftView:self
                                      giftAnimationOptionsWithState:AxcGiftOperationAnimationStateQuit
                                                               gift:gift identifier:identifier];
    }
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftAnimationDelayWithState:gift:identifier:)]) {
        // 入场动画时间时间
        self.giftEnterAnimationDelay = [self.delegate axc_giftView:self
                                       giftAnimationDelayWithState:AxcGiftOperationAnimationStateEnter
                                                              gift:gift identifier:identifier];
        // 出场动画延迟时间
        self.giftQuitAnimationDelay = [self.delegate axc_giftView:self
                                      giftAnimationDelayWithState:AxcGiftOperationAnimationStateQuit
                                                             gift:gift identifier:identifier];
    }
}
#pragma mark - 视图操作
// 获取一个空位视图
- (AxcGiftOperationCell *)emptyOperationCellWithType:(AxcGiftViewArrangementType )type{
    AxcGiftOperationCell *_emptyOperationCell = nil;
    BOOL sequence = (type == AxcGiftViewArrangementTypeTopToBottom);
    for (AxcGiftOperationCell *cell in sequence ? [self visibleCells]: [[self visibleCells] reverseObjectEnumerator]) {
        if (!cell.identifier) { // 无id
            _emptyOperationCell = cell;break;
        }
    }
    return _emptyOperationCell;
}
// 根据id判断cell
- (AxcGiftOperationCell *)operationCellWithIdentifier:(NSString *)identifier{
    AxcGiftOperationCell *existCell = nil;
    for (AxcGiftOperationCell *cell in [self visibleCells]) {
        if ([identifier isEqualToString:cell.identifier]) {
            existCell = cell; break;
        }
    }
    return existCell;
}
#pragma mark - 缓存操作相关
// 替换缓存
- (void)replaceOperationCache:(id)gift identifier:(NSString *)identifier{
    for (int i = 0; i < self.operationCache.count; i ++) {
        NSDictionary *cache = self.operationCache[i];
        if ([cache objectForKey:identifier]) {  // 找到这个缓存
            [self.operationCache replaceObjectAtIndex:i withObject:@{identifier:gift}];
            break;
        }
    }
}
// 根据id拿到缓存
- (id )containsOperationCacheIdentifier:(NSString *)identifier{
    id existGift = nil;
    for (NSDictionary *cache in self.operationCache) {
        id gift = [cache objectForKey:identifier];
        if (gift) {
            existGift = gift; break;
        }
    };
    return existGift;
}
#pragma mark - 刷新相关
// 刷新数据
- (void)reloadData{
    [self.tableView reloadData];
}
// 刷新高度
- (void)reloadHeight{
    CGFloat height = self.showMaxGiftViewCount * self.showMaxGiftViewHeight;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}
#pragma mark - CellDelegate
// 展示即将完成
- (void)giftShowWillComplete:(AxcGiftOperationCell *)cell{ // 回调即将消失
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftWillDisappearWithShowView:gift:identifier:)]) {
        [self.delegate axc_giftView:self giftWillDisappearWithShowView:cell.giftAnimationView gift:cell.gift
                         identifier:cell.identifier];
    }
}
// 展示中
-(void)giftShowWillDidComplete:(AxcGiftOperationCell *)cell{ // 回调正在展示
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftWillDidAppearWithShowView:gift:identifier:)]) {
        [self.delegate axc_giftView:self giftWillDidAppearWithShowView:cell.giftAnimationView gift:cell.gift
                         identifier:cell.identifier];
    }
}
// 自定义出入场
- (CGRect)customAnimationWithState:(AxcGiftOperationAnimationState)state gift:(id)gift identifier:(NSString *)identifier{
    if ([self.delegate respondsToSelector:@selector(axc_giftView:customFrameAnimationWithState:gift:identifier:)]) {
        return [self.delegate axc_giftView:self customFrameAnimationWithState:state gift:gift identifier:identifier];
    }
    return CGRectZero;
}
- (void)giftShowComplete:(AxcGiftOperationCell *)cell{   // 展示完成
    // 回调已经消失
    if ([self.delegate respondsToSelector:@selector(axc_giftView:giftWillDidDisappearWithShowView:gift:identifier:)]) {
        [self.delegate axc_giftView:self giftWillDidDisappearWithShowView:cell.giftAnimationView gift:cell.gift
                         identifier:cell.identifier];
    }
    // 从缓存中取一个，使用队列形式，取出第一个
    NSDictionary *firstCache = self.operationCache.firstObject;
    if (firstCache) {   // 如果缓存队列中有，则进行
        // 移除这个
        [self.operationCache removeObjectAtIndex:0];
        // 获取信息
        NSString *identifier = [firstCache.allKeys firstObject];
        id gift = [firstCache objectForKey:identifier];
        // 自动发送缓存中的礼物
        [self insertGift:gift identifier:identifier];
    }
}
#pragma mark - SET&GET
#pragma mark SET
- (void)setShowMaxGiftViewCount:(NSInteger)showMaxGiftViewCount{
    _showMaxGiftViewCount = showMaxGiftViewCount;
    [self reloadHeight];
}
- (void)setShowMaxGiftViewHeight:(CGFloat)showMaxGiftViewHeight{
    _showMaxGiftViewHeight = showMaxGiftViewHeight;
    [self reloadHeight];
}
#pragma mark GET
- (NSArray <AxcGiftOperationCell *>*)visibleCells{
    return self.tableView.visibleCells;
}
- (AxcGiftOperationCell *)getCellWithIndex:(NSInteger )idx{
    return [self.visibleCells objectAtIndex:idx];
}
#pragma mark - TableView_Delegate & Datasource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.delegate respondsToSelector:@selector(axc_giftView:clickWithShowView:gift:identifier:)]) {
        AxcGiftOperationCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.is_use) [self.delegate axc_giftView:self  // 如果cell处于可使用状态
                                   clickWithShowView:cell.giftAnimationView
                                                gift:cell.gift
                                          identifier:cell.identifier];
    }
}
- (CGFloat )tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.showMaxGiftViewHeight;
}
- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.showMaxGiftViewCount;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AxcGiftOperationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"axc"];
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundView.backgroundColor =
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}
#pragma mark - 懒加载
- (NSMutableArray<NSDictionary *> *)operationCache{
    if (!_operationCache) {
        _operationCache = @[].mutableCopy;
    }
    return _operationCache;
}
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.bounces = NO;
        _tableView.tableHeaderView = [UIView new];
        _tableView.tableFooterView = [UIView new];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.separatorStyle = UITableViewCellEditingStyleNone;     //让tableview不显示分割线
        _tableView.showsVerticalScrollIndicator =
        _tableView.showsHorizontalScrollIndicator = NO;
        [_tableView registerClass:[AxcGiftOperationCell class] forCellReuseIdentifier:@"axc"];
        [self addSubview:_tableView];
    }
    return _tableView;
}

@end
