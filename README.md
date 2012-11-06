# RATilingBackgroundView

A special view which tiles visually identical subviews.  If you use `RATilingBackgroundView`, you can use tiles in your UIScrollView with very little code; it handles bouncing and extrusion for you as well, and does not eat up your `UIScrollViewDelegate`.

## Sample

Look at the [Sample App](https://github.com/evadne/RATilingBackgroundView-Sample).  It contains a vanilla `UIScrollView` and drops the Tiling Background View into the scroll view.

## What’s Inside

You’ll find `RATilingBackgroundView` in this project.  It needs a delegate to work.  Do these things to start using it:

*	Drop the project into your app as a static library dependency.
	
*	Implement `<RATilingBackgroundViewDelegate>`:
	
		- (CGSize) sizeForTilesInTilingBackgroundView:(RATilingBackgroundView *)tilingBackgroundView;
		- (UIView *) newTileForTilingBackgroundView:(RATilingBackgroundView *)tilingBackgroundView;
	
	It’ll ask about the default size for tiles, and will also ask for new tiles whenever the bounds of its containing view has changed and it has no dequeued tiles to cover the area.
	
*	Optionally, set the stretching flags so you can use stretchable images for tiles.

		@property (nonatomic, readwrite, assign) BOOL horizontalStretchingEnabled;	//	YES
		@property (nonatomic, readwrite, assign) BOOL verticalStretchingEnabled;	//	NO

	If you don’t set any stretching flags, the tiles will be stretched horizontally to the same width of the containing view by default.
	
	For example, if you have a square or rectangular image you’d like to repeat, set both flags to `NO`.

## Licensing

This project is in the public domain.  You can use it and embed it in whatever application you sell, and you can use it for evil.  However, it is appreciated if you provide attribution, by linking to the project page ([https://github.com/evadne/RATilingBackgroundView](https://github.com/evadne/RATilingBackgroundView)) from your application.

## Credits

*	[Evadne Wu](http://twitter.com/evadne) at Radius ([Info](http://radi.ws))
