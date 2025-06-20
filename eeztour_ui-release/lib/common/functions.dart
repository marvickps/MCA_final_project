String formatDuration(int totalSeconds) {
  final totalMinutes = totalSeconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  } else if (hours > 0) {
    return '${hours}h';
  } else {
    return '${minutes}m';
  }
}
int parseDuration(String duration) {
  final hourRegex = RegExp(r'(\d+)\s*h');
  final minuteRegex = RegExp(r'(\d+)\s*m');

  int hours = 0;
  int minutes = 0;

  final hourMatch = hourRegex.firstMatch(duration);
  if (hourMatch != null) {
    hours = int.parse(hourMatch.group(1)!);
  }

  final minuteMatch = minuteRegex.firstMatch(duration);
  if (minuteMatch != null) {
    minutes = int.parse(minuteMatch.group(1)!);
  }

  return (hours * 3600) + (minutes * 60);
}
