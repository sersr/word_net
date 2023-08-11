import 'package:flutter/material.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:nop/utils.dart';

import '../../_router/routes.dart';

OverlayMixinDelegate<OverlayMixin>? getDelegate(
    Widget content, Offset position, double height, double width,
    {Duration? delay, OverlayState? Function()? getOverlay}) {
  late final OverlayVerticalPannels pannels;
  pannels = OverlayVerticalPannels(builders: [
    (context) {
      final data = MediaQuery.of(context);
      final size = data.size;

      final paddingTop = data.padding.top;

      Widget child = GestureDetector(
        onTap: () {},
        child: FadeTransition(
          opacity: pannels.controller,
          child: content,
        ),
      );

      var dx = position.dx;
      final dy = position.dy;

      var right = 16.0;
      var left = dx;
      Alignment alignment = Alignment.topLeft;

      final closedRight = dx >= size.width / 2;
      final closedBottom = dy >= size.height / 2;
      if (closedRight) {
        left = 8;
        alignment = Alignment.topRight;
        right = size.width - dx - width;
      }
      var top = dy + height;
      var bottom = 50.0;
      if (closedBottom) {
        if (closedRight) {
          alignment = Alignment.bottomRight;
        } else {
          alignment = Alignment.bottomLeft;
        }

        bottom = size.height - dy;
        top = 20;
      }

      top = top.maxThan(paddingTop);

      child = Container(
        alignment: alignment,
        child: child,
      );
      child = Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: child,
      );
      // }

      return Stack(
        children: [child],
      );
    }
  ]);

  final delegate = OverlayMixinDelegate(
      pannels, const Duration(milliseconds: 120),
      delayDuration: delay ?? const Duration(milliseconds: 300));

  delegate.overlay = OverlayObserverState(
      overlayGetter: getOverlay ??
          () {
            return router.routerDelegate.navigatorKey.currentState?.overlay;
          });
  return delegate;
}
