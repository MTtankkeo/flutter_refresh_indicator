# Introduction
This package provides a refresh indicator widget that is far more flexible and native-like than the default Flutter one, built on top of [flutter_appbar](https://pub.dev/packages/flutter_appbar).

## Preview
The gif image below may appear distorted and choppy due to compression.

![clamping](https://github.com/MTtankkeo/flutter_refresh_indicator/raw/refs/heads/main/image/clamping_preview.gif)
![bouncing](https://github.com/MTtankkeo/flutter_refresh_indicator/raw/refs/heads/main/image/bouncing_preview.gif)

## Usage
The following explains the basic usage of this package.

### When Context
```dart
import 'package:flutter/material.dart' hide RefreshIndicator;

// Other Alias: PullToRefresh and SwipeToRefresh
RefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```

### When Android
This widget for ClampingScrollPhysics.

```dart
ClampingRefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```

### When IOS
This widget for BouncingScrollPhysics.

```dart
BouncingRefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```

### How to define the style globally.

#### Using Material Theme
This is the traditional way to define themes in Flutter.

```dart
MaterialApp(
    theme: ThemeData(
        progressIndicatorTheme: ProgressIndicatorThemeData(
            color: ..., // foregroundColor
            refreshBackgroundColor: ... // backgroundColor
        )
    ),
);
```

#### Using PrimaryRefreshIndicator widget
PrimaryRefreshIndicator defines the refresh indicator style for its descendant widgets, similar to how PrimaryScrollController provides a scroll controller to its descendants.

```dart
PrimaryRefreshIndicator(
    clampingIndicatorBuilder: (...), // Custom indicator for Clamping
    bouncingIndicatorBuilder: (...), // Custom indicator for Bouncing
)
```
