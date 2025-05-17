
# Introduction
This package provides a refresh indicator widget that is far more flexible and native-like than the default Flutter one, built on top of [flutter_appbar](https://pub.dev/packages/flutter_appbar).

# Usage
The following explains the basic usage of this package.

## When Context

```dart
import 'package:flutter/material.dart' hide RefreshIndicator;

RefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```

## When Android
This widget for ClampingScrollPhysics.

```dart
ClampingRefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```

## When IOS
This widget for BouncingScrollPhysics.

```dart
BouncingRefreshIndicator(
    onRefresh: ..., // AsyncCallback
    child: ...
),
```