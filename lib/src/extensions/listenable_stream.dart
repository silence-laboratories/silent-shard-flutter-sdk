import 'dart:async';

import 'package:flutter/foundation.dart';

typedef Transform<R, T extends Listenable> = R Function(T);

extension Streamable<T extends Listenable> on T {
  Stream<R> toStream<R>(Transform<R, T> transform) {
    VoidCallback? listener;
    final controller = StreamController<R>();

    controller.onListen = () {
      try {
        listener = () => controller.add(transform(this));
        addListener(listener!);
        controller.add(transform(this));
      } catch (e) {
        controller.close();
      }
    };

    controller.onCancel = () {
      try {
        if (listener == null) return;
        removeListener(listener!);
        listener = null;
      } catch (e) {/**/}
    };

    return controller.stream;
  }
}
