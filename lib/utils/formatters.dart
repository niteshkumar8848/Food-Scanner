String formatDateTime(DateTime dateTime) {
  final d = dateTime;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
