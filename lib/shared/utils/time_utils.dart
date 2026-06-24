String formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatDurationShort(Duration duration) {
  if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  if (duration.inMinutes > 0) return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  return '${duration.inSeconds}s';
}
