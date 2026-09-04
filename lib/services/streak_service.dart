class StreakInfo {
  final int current;
  final int longest;
  StreakInfo({required this.current, required this.longest});
}

String dateStr(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String todayStr() => dateStr(DateTime.now());

String addDays(String date, int n) {
  final parts = date.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1], parts[2]).add(Duration(days: n));
  return dateStr(d);
}

StreakInfo computeStreak(List<String> sortedDates) {
  if (sortedDates.isEmpty) return StreakInfo(current: 0, longest: 0);
  final dateSet = sortedDates.toSet();

  var longest = 1, run = 1;
  for (var i = 1; i < sortedDates.length; i++) {
    if (addDays(sortedDates[i - 1], 1) == sortedDates[i]) {
      run += 1;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
  }

  var cursor = dateSet.contains(todayStr()) ? todayStr() : addDays(todayStr(), -1);
  var current = 0;
  while (dateSet.contains(cursor)) {
    current += 1;
    cursor = addDays(cursor, -1);
  }

  return StreakInfo(current: current, longest: longest);
}
