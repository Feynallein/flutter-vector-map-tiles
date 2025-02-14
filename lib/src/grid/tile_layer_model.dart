import 'package:flutter/widgets.dart';
import '../../vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'debounce.dart';
import 'slippy_map_translator.dart';
import 'tile_model.dart';
import 'tile_zoom.dart';

class TileLayerModel extends ChangeNotifier {
  final String id;
  final Theme theme;
  final Duration delay;
  final Duration initialDelay;
  Tileset? tileset;
  TileTranslation? translation;
  final VectorTileModel tileModel;
  var _disposed = false;
  var visible = true;
  late final ScheduledDebounce debounce;
  TileZoom lastRenderedZoom = TileZoom.undefined();
  var lastRenderedVisible = true;
  TileIdentity? lastRenderedTile;
  var _renderedOnce = false;

  TileLayerModel(
      {required this.theme,
      required this.id,
      required this.delay,
      required this.initialDelay,
      required this.tileset,
      required this.tileModel}) {
    debounce = ScheduledDebounce(_makeVisible,
        delay: delay,
        jitter: Duration(milliseconds: delay.inMilliseconds ~/ 2),
        maxAge: Duration(milliseconds: delay.inMilliseconds * 20));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _makeVisible() {
    visible = true;
    notifyListeners();
  }

  TileZoom updateRendering() {
    final previousRenderedZoom = lastRenderedZoom;
    lastRenderedZoom = tileModel.zoomProvider.provide();
    lastRenderedVisible = visible;
    lastRenderedTile = tileModel.translation?.translated;
    if (previousRenderedZoom != lastRenderedZoom &&
        nextDelay().inMilliseconds > 0) {
      visible = false;
      debounce.update();
    }
    if (visible) {
      _renderedOnce = true;
    }
    return lastRenderedZoom;
  }

  Duration nextDelay() {
    if (!_renderedOnce && initialDelay.inMilliseconds > 0) {
      return initialDelay;
    }
    return delay;
  }

  bool hasChanged() =>
      visible != lastRenderedVisible ||
      lastRenderedZoom != tileModel.zoomProvider.provide() ||
      lastRenderedTile != tileModel.translation?.translated;
}
