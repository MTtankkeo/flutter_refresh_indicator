# Introduction
This package provides a refresh indicator widget that is far more flexible and native-like than the default Flutter one, built on top of [flutter_appbar](https://pub.dev/packages/flutter_appbar).

## Preview
The gif image below may appear distorted and choppy due to compression.

![clamping](https://github.com/user-attachments/assets/979f6cef-5f32-4cdd-b9c4-627d56598a42)
![bouncing](https://github.com/user-attachments/assets/e2ff15b8-838a-4e43-babf-dca2f0d22841)

## Usage
The following explains the basic usage of this package.

### When Context
```dart
import 'package:flutter/material.dart' hide RefreshIndicator;

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
            refreshBackgroundColor: ... // boregroundColor
        )
    ),
);
```

#### Using PrimaryRefreshIndicator widget
PrimaryRefreshIndicator defines the style of its descendant related refresh indicator widgets, similar to how PrimaryScrollController defines the controller for its descendant widgets.

```dart
PrimaryRefreshIndicator(
    clamping: RefreshIndicatorStyle(...),
    bouncing: RefreshIndicatorStyle(...)
)
```