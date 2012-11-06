//
//  RATilingBackgroundView.h
//  RATilingBackgroundView
//
//  Created by Evadne Wu on 11/6/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RATilingBackgroundViewDelegate.h"

@interface RATilingBackgroundView : UIView

@property (nonatomic, readwrite, assign) BOOL horizontalStretchingEnabled;	//	YES
@property (nonatomic, readwrite, assign) BOOL verticalStretchingEnabled;	//	NO
@property (nonatomic, readwrite, weak) id<RATilingBackgroundViewDelegate> delegate;

@end
