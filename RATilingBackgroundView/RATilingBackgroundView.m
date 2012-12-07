//
//  RATilingBackgroundView.m
//  RATilingBackgroundView
//
//  Created by Evadne Wu on 11/6/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "RATilingBackgroundView.h"

@interface RATilingBackgroundView ()
@property (nonatomic, readwrite, assign) CGPoint offset;
@property (nonatomic, readonly, strong) NSMutableArray *visibleTiles;
@property (nonatomic, readonly, strong) NSMutableArray *dequeuedTiles;
- (void) reset;
- (void) setUpObservations;
- (void) tearDownObservations;
@end

@implementation RATilingBackgroundView
@synthesize offset = _offset;
@synthesize visibleTiles = _visibleTiles;
@synthesize dequeuedTiles = _dequeuedTiles;

- (id) initWithCoder:(NSCoder *)aDecoder {

	self = [super initWithCoder:aDecoder];
	if (!self)
		return nil;
	
	[self commonInit];
	
	_horizontalStretchingEnabled = [aDecoder decodeBoolForKey:@"horizontalStretchingEnabled"];
	_verticalStretchingEnabled = [aDecoder decodeBoolForKey:@"verticalStretchingEnabled"];
	
	return self;

}

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self commonInit];
	
	return self;

}

- (void) commonInit {

	_horizontalStretchingEnabled = YES;
	_verticalStretchingEnabled = NO;
	_offset = CGPointZero;

}

- (void) encodeWithCoder:(NSCoder *)aCoder {

	[super encodeWithCoder:aCoder];
	
	[aCoder encodeBool:_horizontalStretchingEnabled forKey:@"horizontalStretchingEnabled"];
	[aCoder encodeBool:_verticalStretchingEnabled forKey:@"verticalStretchingEnabled"];

}

- (void) willMoveToSuperview:(UIView *)newSuperview {
	
	[super willMoveToSuperview:newSuperview];
	
	if (self.superview) {
		[self tearDownObservations];
	}

}

- (void) didMoveToSuperview {
	
	[super didMoveToSuperview];
	
	[self reset];
	
	if (self.superview) {
		[self setUpObservations];
	}

}

- (void) layoutSubviews {

	NSCParameterAssert(self.delegate);
	
	[super layoutSubviews];
		
	NSArray *tilingRects = [self tilingRects];
	NSMutableArray *unusedVisibleTiles = [self.visibleTiles mutableCopy];
	
	[tilingRects enumerateObjectsUsingBlock:^(NSValue *rectValue, NSUInteger idx, BOOL *stop) {
		
		CGRect rect = [rectValue CGRectValue];
		
		UIView *tile = [unusedVisibleTiles count] ?
			[unusedVisibleTiles objectAtIndex:0] :
			nil;
		
		if (tile) {
			[unusedVisibleTiles removeObject:tile];
		} else {
			tile = [self newTile];
			[self addSubview:tile];
			[self.visibleTiles addObject:tile];
		}
		
		tile.frame = rect;
		
		NSCParameterAssert(![unusedVisibleTiles containsObject:tile]);
		NSCParameterAssert([self.visibleTiles containsObject:tile]);
		NSCParameterAssert(![self.dequeuedTiles containsObject:tile]);
		NSCParameterAssert([self.subviews containsObject:tile]);
		
	}];
	
	[self.visibleTiles removeObjectsInArray:unusedVisibleTiles];
	[self.dequeuedTiles addObjectsFromArray:unusedVisibleTiles];
	
	for (UIView *unusedVisibleTile in unusedVisibleTiles) {
		[unusedVisibleTile removeFromSuperview];
	}
	
	for (UIView *dequeuedTile in self.dequeuedTiles) {
		NSCParameterAssert(![self.visibleTiles containsObject:dequeuedTile]);
	}
	
	NSCParameterAssert([[NSSet setWithArray:self.subviews] isEqualToSet:[NSSet setWithArray:self.visibleTiles]]);
	
}

- (CGSize) tileSize {

	CGSize requestedTileSize = [self.delegate sizeForTilesInTilingBackgroundView:self];
	
	return (CGSize){
		
		.width = self.horizontalStretchingEnabled ?
			CGRectGetWidth(self.bounds) :
			requestedTileSize.width,
			
		.height = self.verticalStretchingEnabled ?
			CGRectGetHeight(self.bounds) :
			requestedTileSize.height
		
	};

}

- (NSArray *) tilingRects {
	
	CGSize tileSize = [self tileSize];
	CGSize boundsSize = (CGSize){
		.width = CGRectGetWidth(self.bounds) + ABS(self.offset.x),
		.height = CGRectGetHeight(self.bounds) + ABS(self.offset.y)
	};
		
	NSUInteger numberOfTiles = ceilf(boundsSize.width / tileSize.width) *
		ceilf(boundsSize.height / tileSize.height);
		
	if (!numberOfTiles)
		return @[];
	
	NSMutableArray *tileRects = [NSMutableArray arrayWithCapacity:numberOfTiles];
	
	for (CGFloat offsetX = self.offset.x; offsetX < boundsSize.width; offsetX += tileSize.width) {
	
		for (CGFloat offsetY = self.offset.y; offsetY < boundsSize.height; offsetY += tileSize.height) {
			
			CGRect rect = (CGRect){
				.origin.x = offsetX,
				.origin.y = offsetY,
				.size = tileSize
			};
			
			[tileRects addObject:[NSValue valueWithCGRect:rect]];
		
		}
	
	}
	
	return tileRects;

}

- (UIView *) newTile {

	NSMutableArray *dequeuedTiles = self.dequeuedTiles;
	UIView *tile = [dequeuedTiles count] ?
		[dequeuedTiles objectAtIndex:0] :
		nil;
	
	if (tile) {
		[dequeuedTiles removeObject:tile];
		return tile;
	}
	
	return [self.delegate newTileForTilingBackgroundView:self];

}

- (NSMutableArray *) visibleTiles {

	if (!_visibleTiles) {
	
		_visibleTiles = [NSMutableArray array];
	
	}
	
	return _visibleTiles;

}

- (NSMutableArray *) dequeuedTiles {

	if (!_dequeuedTiles) {
	
		_dequeuedTiles = [NSMutableArray array];
	
	}
	
	return _dequeuedTiles;

}

- (void) reset {

	self.offset = CGPointZero;
	
	[self setNeedsLayout];

}

- (void) setUpObservations {

	UIView *target = self.superview;
	NSCParameterAssert(target);
	
	if ([target respondsToSelector:@selector(contentOffset)]) {
	
		[target addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(void *)self];
	
	}
	
	[target addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(void *)self];

}

- (void) tearDownObservations {

	UIView *target = self.superview;
	NSCParameterAssert(target);
	
	if ([target respondsToSelector:@selector(contentOffset)]) {
	
		[target removeObserver:self forKeyPath:@"contentOffset" context:(void *)self];
	
	}
	
	[target removeObserver:self forKeyPath:@"bounds" context:(void *)self];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	[self setNeedsLayout];
	
	if (object == self.superview) {
	
		if ([keyPath isEqualToString:@"contentOffset"]) {
		
			CGPoint toContentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
			CGSize tileSize = [self tileSize];
			
			self.offset = (CGPoint){
				
				fmodf(-1 * toContentOffset.x, tileSize.width) -
					(self.horizontalStretchingEnabled ?
						0.0f :
						ceilf(CGRectGetWidth(self.bounds) / tileSize.width) * tileSize.width),
				
				fmodf(-1 * toContentOffset.y, tileSize.height) -
					(self.verticalStretchingEnabled ?
						0.0f :
						ceilf(CGRectGetHeight(self.bounds) / tileSize.height) * tileSize.height)
					
			};
		
		} else if ([keyPath isEqualToString:@"bounds"]) {
		
			self.frame = self.superview.bounds;
		
		}
	
	}
	
}

@end
