//
//  WSReorderableCollectionViewFlowLayout.m
//  OneUpDraggable
//
//  Created by Wahyu Sumartha on 7/19/13.
//  Copyright (c) 2013 Mindvalley. All rights reserved.
//

#import "WSReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define WS_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_WSSUPPORT_H_
CG_INLINE CGPoint
WS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, WSScrollingDirection) {
    WSScrollingDirectionUnknown = 0,
    WSScrollingDirectionUp,
    WSScrollingDirectionDown,
    WSScrollingDirectionLeft,
    WSScrollingDirectionRight
};

static NSString * const kWSScrollingDirectionKey = @"kWSScrollingDirectionKey";
static NSString * const kWSCollectionViewKeyPath = @"collectionView";

@interface CADisplayLink (WSUserInfo)
@property (nonatomic, copy) NSDictionary *WS_userInfo;
@end

@implementation CADisplayLink (WSUserInfo)
- (void)setWS_userInfo:(NSDictionary *)WS_userInfo
{
    objc_setAssociatedObject(self, "WS_userInfo", WS_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)WS_userInfo
{
    return objc_getAssociatedObject(self, "WS_userInfo");
}
@end

@interface UICollectionViewCell (WSReorderableCollectionViewFlowLayout)

- (UIImage *)WS_rasterizedImage;

@end

@implementation UICollectionViewCell (WSReorderableCollectionViewFlowLayout)

- (UIImage *)WS_rasterizedImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface WSReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;

@property (nonatomic, assign, readonly) id<WSReorderableCollectionViewDataSource> dataSource;
@property (nonatomic, assign, readonly) id<WSReorderableCollectionViewDelegateFlowLayout> delegate;

@end

@implementation WSReorderableCollectionViewFlowLayout

/**
 *  Set Default Configuration for 
 *  scrolling speed and scrollingTriggerEdgeInsets
 */
- (void)setDefaults
{
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInset = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

/**
 *  Setup Long Press Gesture to this object (collection view)
 */
- (void)setupCollectionView
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Setup Long Press Gesture Recognizer
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
}

- (id)init
{
    self = [super init];
    
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kWSCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kWSCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:kWSCollectionViewKeyPath];
}

- (id<WSReorderableCollectionViewDataSource>)dataSource
{
    return (id<WSReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<WSReorderableCollectionViewDelegateFlowLayout>)delegate
{
    return (id<WSReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}


#pragma mark -
#pragma mark - Selector Methods

#pragma mark - Handle Long Gesture 
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[ gestureRecognizer locationInView:self.collectionView]];
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
                ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell WS_rasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[collectionViewCell WS_rasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                __strong typeof (self) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    highlightedImageView.alpha = 0.0;
                    imageView.alpha = 1.0;
                }
            } completion:^(BOOL finished) {
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [highlightedImageView removeFromSuperview];
                    
                    if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                        [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                    }
                }
            }];
            
            [self invalidateLayout];
            
        } break;
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
            }
            
            self.selectedItemIndexPath = nil;
            self.currentViewCenter = CGPointZero;
            
            UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
            
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                    strongSelf.currentView.center = layoutAttributes.center;
                }
            } completion:^(BOOL finished) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.currentView removeFromSuperview];
                strongSelf.currentView = nil;
                [strongSelf invalidateLayout];
                
                if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                    [strongSelf.delegate collectionView:strongSelf.collectionView layout:self didEndDraggingItemAtIndexPath:currentIndexPath];
                }
            }];
            
        } break;
        default:
            break;
    }
}

#pragma mark - Handle Pan Gesture 
-  (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    
}

#pragma mark - Key Value Observing Methods 
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kWSCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        }
    }
    
}

@end
