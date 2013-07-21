//
//  WSReorderableCollectionViewFlowLayout.h
//  OneUpDraggable
//
//  Created by Wahyu Sumartha on 7/19/13.
//  Copyright (c) 2013 Mindvalley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSReorderableCollectionViewFlowLayout : UICollectionViewFlowLayout<UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat scrollingSpeed;
@property (nonatomic, assign) UIEdgeInsets scrollingTriggerEdgeInset;
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@end

@protocol WSReorderableCollectionViewDataSource <UICollectionViewDataSource>

@optional
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol WSReorderableCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

@optional
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
@end
