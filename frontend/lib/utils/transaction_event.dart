import 'package:flutter/material.dart';

class TransactionEvent {
  static final ValueNotifier<int> refresher = ValueNotifier(0);

  static void triggerRefresh() {
    refresher.value++;
  }
}