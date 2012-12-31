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
		
	NSPointerArray *unusedVisibleTiles = [NSPointerArray weakObjectsPointerArray];
	for (UIView *visibleTile in self.visibleTiles)
		[unusedVisibleTiles addPointer:(void *)visibleTile];
	
	NSUInteger tileRectsCount = 0;
	[self getPrimitiveTilingRects:NULL count:&tileRectsCount];
	
	CGRect * const tileRects = malloc(tileRectsCount * sizeof(CGRect));
	memset(tileRects, 0, tileRectsCount * sizeof(CGRect));
	
	[self getPrimitiveTilingRects:tileRects count:&tileRectsCount];
	
	NSUInteger const unusedVisibleTilesCount = [unusedVisibleTiles count];
	
	for (NSUInteger tileRectIndex = 0; tileRectIndex < tileRectsCount; tileRectIndex++) {
	
		CGRect rect = tileRects[tileRectIndex];
		UIView *tile = nil;
		
		if (!!unusedVisibleTilesCount && (tileRectIndex <= (unusedVisibleTilesCount - 1))) {
			
			tile = (UIView *)[unusedVisibleTiles pointerAtIndex:tileRectIndex];
			[unusedVisibleTiles replacePointerAtIndex:tileRectIndex withPointer:NULL];
						
		} else {
			
			tile = [self newTile];
			[self addSubview:tile];
			[self.visibleTiles addObject:tile];
			
		}
				
		tile.frame = rect;
		
	}
	
	free(tileRects);
	NSArray *leftoverTiles = [unusedVisibleTiles allObjects];
	
	[self.visibleTiles removeObjectsInArray:leftoverTiles];
	[self.dequeuedTiles addObjectsFromArray:leftoverTiles];
	
	for (UIView *unusedVisibleTile in leftoverTiles) {
		[unusedVisibleTile removeFromSuperview];
	}
	
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

- (void) getPrimitiveTilingRects:(CGRect *)outRects count:(NSUInteger *)outCount {

	NSCParameterAssert(outCount);
	
	CGSize const tileSize = [self tileSize];
	CGSize const boundsSize = (CGSize){
		.width = CGRectGetWidth(self.bounds),
		.height = CGRectGetHeight(self.bounds)
	};
	
	CGFloat const stepX = tileSize.width;
	CGFloat const fromX = fmodf(self.offset.x, stepX);
	CGFloat const toX = boundsSize.width;
	CGFloat const stepY = tileSize.height;
	CGFloat const fromY = fmodf(self.offset.y, stepY);
	CGFloat const toY = boundsSize.height;
	
	NSUInteger const numberOfTilesX = (NSUInteger)(ceilf(toX / stepX) - floorf(fromX / stepX));
	NSUInteger const numberOfTilesY = (NSUInteger)(ceilf(toY / stepY) - floorf(fromY / stepY));
	NSUInteger const numberOfTiles = numberOfTilesX * numberOfTilesY;
	
	if (outCount) {
		*outCount = numberOfTiles;
	}

	if (!outRects)
		return;
	
	NSUInteger rectIndex = 0;
	for (NSUInteger indexX = 0; indexX < numberOfTilesX; indexX++)
	for (NSUInteger indexY = 0; indexY < numberOfTilesY; indexY++) {
		
		NSCParameterAssert(rectIndex < numberOfTiles);
		
		outRects[rectIndex] = (CGRect){
			.origin.x = fromX + indexX * stepX,
			.origin.y = fromY + indexY * stepY,
			.size = tileSize
		};
		
		rectIndex++;
	
	}
	
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
