import 'dart:io';

void main() {
  final file = File('lib/features/gantt/presentation/gantt_screen.dart');
  final lines = file.readAsLinesSync();
  // Keep first 109 lines (indices 0 to 108)
  file.writeAsStringSync(lines.sublist(0, 109).join('\n') + '\n');
}
