import 'package:flutter/material.dart';
import 'package:simple_sheet_music/src/extension/list_extension.dart';
import 'package:simple_sheet_music/src/glyph_metadata.dart';
import 'package:simple_sheet_music/src/glyph_path.dart';
import 'package:simple_sheet_music/src/music_objects/clef/clef_type.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol_metrics.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol_renderer.dart';
import 'package:simple_sheet_music/src/music_objects/notes/accidental.dart';
import 'package:simple_sheet_music/src/music_objects/notes/legerline.dart';
import 'package:simple_sheet_music/src/music_objects/notes/note_duration.dart';
import 'package:simple_sheet_music/src/music_objects/notes/note_pitch.dart';
import 'package:simple_sheet_music/src/music_objects/notes/noteflag_type.dart';
import 'package:simple_sheet_music/src/music_objects/notes/notehead_type.dart';
import 'package:simple_sheet_music/src/music_objects/notes/positions.dart';
import 'package:simple_sheet_music/src/music_objects/notes/stem_direction.dart';
import 'package:simple_sheet_music/src/musical_context.dart';
import 'package:simple_sheet_music/src/sheet_music_layout.dart';
import 'package:simple_sheet_music/src/measure/measure.dart';
import 'package:simple_sheet_music/src/music_objects/notes/single_note/note.dart';

// 
extension BeamMetrics on NoteMetrics {
  Offset get globalStemTip => stemTipOffset + Offset(symbolX, staffLineCenterY);
  Offset get globalStemRoot => stemRootOffset + Offset(symbolX, staffLineCenterY);
}
// BeamGroups を Metrics に変換する関数
List<List<NoteMetrics>> beamGroupsMetrics(
  Measure measure,
  List<MusicalSymbolMetrics> metrics,
) {
  final noteMetricsMap = {
    for (final m in metrics.whereType<NoteMetrics>()) m.note: m
  };

  return measure.beamGroups
      .map((group) => group.map((n) => noteMetricsMap[n]!).toList())
      .toList();
}


class BeamPainter extends CustomPainter {
  final List<List<NoteMetrics>> beamGroups;

  BeamPainter(this.beamGroups);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4;

    for (final group in beamGroups) {
      if (group.length < 2) continue;

      final first = group.first;
      final last = group.last;

      // stem tip のグローバル座標
      final start = first.globalStemTip;
      final end = last.globalStemTip;

      // メインのビーム
      canvas.drawLine(start, end, paint);

      // 16分音符以上なら追加ビーム
      if (group.any((n) => toQuarterLength(n.note) <= 0.25)) {
        const offsetY = 6.0;
        final start2 = start.translate(0, offsetY);
        final end2 = end.translate(0, offsetY);
        canvas.drawLine(start2, end2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BeamPainter oldDelegate) =>
      oldDelegate.beamGroups != beamGroups;
}

