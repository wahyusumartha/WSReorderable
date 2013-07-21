//
//  MainViewController.h
//  OneUpDraggable
//
//  Created by Wahyu Sumartha on 7/22/13.
//  Copyright (c) 2013 Mindvalley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSReorderableCollectionViewFlowLayout.h"

@interface MainViewController : UIViewController<WSReorderableCollectionViewDataSource, WSReorderableCollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet WSReorderableCollectionViewFlowLayout *collectionViewLayout;

@end
