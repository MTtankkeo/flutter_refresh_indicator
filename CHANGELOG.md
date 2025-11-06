## 1.0.1
- Fixed an issue where the fade-out occurred even though the pull animation had not finished.

## 1.0.2
- Fixed a critical bug related to BouncingRefreshIndicator.

## 1.0.3
- Added `edgeOffset` option to ClampingRefreshIndicator for customizing the top inset.

- Renamed `maxDragPercent` to `maxDragDistance` and changed its unit from percentage to pixels in ClampingRefreshIndicator.

## 1.0.4
- Fixed an issue where unnecessary animations were triggered during PointerUp in ClampingRefreshIndicator.

## 1.1.0 ~ 1.1.1
- Updated to support flutter_appbar version 1.5.0, which added the NestedScrollConnectionPropagation.directional option.

- Fixed an issue by adding handling for Pointer Cancel events to prevent bugs where the indicator would freeze when gestures are canceled midway.

## 1.2.0
- Removed the `RefreshIndicatorStyle` class and added support for customizing indicators directly through `ClampingRefreshIndicatorBuilder` and `BouncingRefreshIndicatorBuilder`.

- Renamed the `GlobalListener` class to `RefreshIndicatorListener`.

- Changed the default indicator in the `BouncingRefreshIndicator` widget to `CupertinoActivityIndicator`.
