import 'package:flutter/widgets.dart';

class LogObserver extends NavigatorObserver {
  LogObserver({this.onRouteChanged});

  final void Function(String from, String to)? onRouteChanged;

  String _currentRoute = '/';
  String get currentRoute => _currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(previousRoute);
    super.didRemove(route, previousRoute);
  }

  void _updateRoute(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty || name == _currentRoute) return;
    final prev = _currentRoute;
    _currentRoute = name;
    onRouteChanged?.call(prev, name);
  }
}
