//
//  FSCalendarHeader.m
//  Pods
//
//  Created by Wenchao Ding on 29/1/15.
//
//

#import "FSCalendarHeader.h"
#import "FSCalendar.h"
#import "UIView+FSExtension.h"
#import "NSDate+FSExtension.h"

#define kBlueText [UIColor colorWithRed:14/255.0 green:69/255.0 blue:221/255.0 alpha:1.0]

@interface FSCalendarHeader ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (copy, nonatomic) NSDateFormatter            *dateFormatter;
@property (weak, nonatomic) UICollectionView           *collectionView;
@property (weak, nonatomic) UICollectionViewFlowLayout *collectionViewFlowLayout;

- (void)updateAlphaForCell:(UICollectionViewCell *)cell;

@end

@implementation FSCalendarHeader

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _dateFormatter            = [[NSDateFormatter alloc] init];
    _scrollDirection          = UICollectionViewScrollDirectionHorizontal;
    _minimumDate              = [NSDate fs_dateWithYear:1970 month:1 day:1];
    _maximumDate              = [NSDate fs_dateWithYear:2099 month:12 day:31];

    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewFlowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionViewFlowLayout.minimumInteritemSpacing = 0;
    collectionViewFlowLayout.minimumLineSpacing = 0;
    collectionViewFlowLayout.itemSize = CGSizeMake(1, 1);
    self.collectionViewFlowLayout = collectionViewFlowLayout;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewFlowLayout];
    collectionView.scrollEnabled = NO;
    collectionView.userInteractionEnabled = NO;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self addSubview:collectionView];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    self.collectionView = collectionView;
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _collectionView.frame = CGRectMake(0, self.fs_height*0.1, self.fs_width, self.fs_height*0.9);
    _collectionView.contentInset = UIEdgeInsetsZero;
    _collectionViewFlowLayout.itemSize = CGSizeMake(self.fs_width * 0.5,
                                                    _collectionView.fs_height);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_maximumDate fs_monthsFrom:_minimumDate] + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:100];
    if (!titleLabel) {
        titleLabel = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        titleLabel.tag = 100;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:titleLabel];
    }
    titleLabel.font = _appearance.headerTitleFont;
    titleLabel.textColor = _appearance.headerTitleColor;
    NSDate *date = [_minimumDate fs_dateByAddingMonths:indexPath.item];
    _dateFormatter.dateFormat = _appearance.headerDateFormat;
    titleLabel.text = [_dateFormatter stringFromDate:date];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateAlphaForCell:cell];
}

#pragma mark - Properties

- (void)setScrollOffset:(CGFloat)scrollOffset
{
    if (_scrollOffset != scrollOffset) {
        _scrollOffset = scrollOffset;
    }
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        _collectionView.contentOffset = CGPointMake((_scrollOffset-0.5)*_collectionViewFlowLayout.itemSize.width, 0);
    } else {
        _collectionView.contentOffset = CGPointMake(0, _scrollOffset * _collectionViewFlowLayout.itemSize.height);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *cells = _collectionView.visibleCells;
        [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self updateAlphaForCell:obj];
        }];
    });
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        _collectionViewFlowLayout.scrollDirection = scrollDirection;
        CGPoint newOffset = CGPointMake(
                                        scrollDirection == UICollectionViewScrollDirectionHorizontal ? (_scrollOffset-0.5)*_collectionViewFlowLayout.itemSize.width : 0,
                                        scrollDirection == UICollectionViewScrollDirectionVertical ? _scrollOffset * _collectionViewFlowLayout.itemSize.height : 0
                                        );
        _collectionView.contentOffset = newOffset;
        if (scrollDirection == UICollectionViewScrollDirectionVertical) {
            _collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(0, self.fs_width*0.25, 0, self.fs_width*0.25);
        } else {
            _collectionViewFlowLayout.sectionInset = UIEdgeInsetsZero;
        }
        [_collectionView reloadData];
    }
}

#pragma mark - Public

- (void)reloadData
{
    [_collectionView reloadData];
}

#pragma mark - Private

- (void)updateAlphaForCell:(UICollectionViewCell *)cell
{
    [[cell.contentView viewWithTag:100] setFrame:cell.contentView.bounds];
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        CGFloat position = [cell convertPoint:CGPointMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds)) toView:self].x;
        CGFloat center = CGRectGetMidX(self.bounds);
        cell.contentView.alpha = 1.0 - (1.0-_appearance.headerMinimumDissolvedAlpha)*ABS(center-position)/_collectionViewFlowLayout.itemSize.width;
    } else {
        CGFloat position = [cell convertPoint:CGPointMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds)) toView:self].y;
        CGFloat center = CGRectGetMidY(self.bounds);
        cell.contentView.alpha = 1.0 - (1.0-_appearance.headerMinimumDissolvedAlpha)*ABS(center-position)/_collectionViewFlowLayout.itemSize.height;
    }
}


@end
