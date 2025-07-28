import 'dart:core';

import 'package:simple_sheet_music/src/glyph_metadata.dart';
import 'package:simple_sheet_music/src/glyph_path.dart';
import 'package:simple_sheet_music/src/music_objects/clef/clef.dart';
import 'package:simple_sheet_music/src/music_objects/clef/clef_type.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol.dart';
import 'package:simple_sheet_music/src/music_objects/interface/musical_symbol_metrics.dart';
import 'package:simple_sheet_music/src/music_objects/key_signature/key_signature.dart';
import 'package:simple_sheet_music/src/musical_context.dart';
import 'package:simple_sheet_music/src/music_objects/notes/single_note/note.dart';
import 'package:simple_sheet_music/src/music_objects/notes/note_duration.dart';

import '../music_objects/key_signature/keysignature_type.dart';

/// Represents a measure in sheet music.
class Measure {
  /// Creates a new instance of the [Measure] class.
  ///
  /// The [musicalSymbols] parameter is a list of musical symbols that make up the measure.
  /// The [isNewLine] parameter indicates whether the measure is a new line in the sheet music.
  ///
  /// Throws an [AssertionError] if the [musicalSymbols] list is empty.
  const Measure(
    this.musicalSymbols, {
    this.isNewLine = false,
    this.timeSignature = int 4,
  }) : assert(musicalSymbols.length != 0);

  /// The list of musical symbols that make up the measure.
  final List<MusicalSymbol> musicalSymbols;

  /// Indicates whether the measure is a new line in the sheet music.
  final bool isNewLine;

  final int timeSignature; // 拍子記号、例: 4/4拍子なら4

  List<List<Note>> beamGroups = [];//隣り合う8分音符以下をビームで繋ぐ

  void computeBeams() {
    beamGroups.clear();

    // 累積の拍位置
    double currentBeat = 0;
    List<Note> currentGroup = [];

    for (final symbol in musicalSymbols) {
      if (symbol is! Note) {
        // ノート以外が出てきたらグループを確定
        if (currentGroup.length > 1) {
          beamGroups.add(List<Note>.from(currentGroup));
        }
        currentGroup.clear();
        continue;
      }

      final note = symbol;

      // 8分音符以下が対象
      final durationInQuarter = toQuarterLength(note);
      final isBeamable = durationInQuarter <= 0.5;

      if (isBeamable) {
        // 拍が変わったら確定
        final beatStart = currentBeat.floor();
        final beatEnd = (currentBeat + durationInQuarter).floor();

        if (currentGroup.isEmpty) {
          currentGroup.add(note);
        } else if (beatStart == currentBeat.floor()) {
          // 同じ拍 → グループ継続
          currentGroup.add(note);
        } else {
          // 拍を跨いだ → いったん確定
          if (currentGroup.length > 1) {
            beamGroups.add(List<Note>.from(currentGroup));
          }
          currentGroup = [note];
        }
      } else {
        // ビーム対象外 → グループ確定
        if (currentGroup.length > 1) {
          beamGroups.add(List<Note>.from(currentGroup));
        }
        currentGroup.clear();
      }

      currentBeat += durationInQuarter;
    }

    // 最後のグループを確定
    if (currentGroup.length > 1) {
      beamGroups.add(List<Note>.from(currentGroup));
    }
  }

  /// Sets the context for the measure and returns a list of musical symbol metrics.
  ///
  /// The [context] parameter is the musical context in which the measure is being rendered.
  /// The [metadata] parameter provides metadata for the glyphs used in the measure.
  /// The [paths] parameter provides the paths for the glyphs used in the measure.
  ///
  /// Returns a list of [MusicalSymbolMetrics] objects representing the metrics of each musical symbol in the measure.
  List<MusicalSymbolMetrics> setContext(
    MusicalContext context,
    GlyphMetadata metadata,
    GlyphPaths paths,
  ) {
    final result = <MusicalSymbolMetrics>[];
    var symbolContext = context;
    for (final symbol in musicalSymbols) {
      final symbolMetrics = symbol.setContext(symbolContext, metadata, paths);
      symbolContext = symbolContext.update(symbol);
      result.add(symbolMetrics);
    }
    return result;
  }

  ClefType? get lastClefType {
    for (final symbol in musicalSymbols.reversed) {
      if (symbol is Clef) {
        return symbol.clefType;
      }
    }
    return null;
  }

  KeySignatureType? get lastKeySignatureType {
    for (final symbol in musicalSymbols.reversed) {
      if (symbol is KeySignature) {
        return symbol.keySignatureType;
      }
    }
    return null;
  }

  MusicalContext updateContext(MusicalContext context) => context.updateWith(
        clefType: lastClefType,
        keySignatureType: lastKeySignatureType,
      );
}

double toQuarterLength(Note note) {
    // switch文を使って、音符の種類に応じた持続時間を返す
    final base = switch (note.noteDuration) {
      NoteDuration.whole => 4.0,
      NoteDuration.half => 2.0,
      NoteDuration.quarter => 1.0,
      NoteDuration.eighth => 0.5,
      NoteDuration.sixteenth => 0.25,
      _ => 1.0, // デフォルトは四分音符
    };
    return base * (note.isDotted ? 1.5 : 1.0);
    //return base; //付点音符は使わない想定
  }
