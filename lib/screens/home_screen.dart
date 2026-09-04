import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';

class HomeScreen extends StatefulWidget {
  final SecretKey vaultKey;
  final VoidCallback onLock;
  const HomeScreen({super.key, required this.vaultKey, required this.onLock});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _entryCtrl = TextEditingController();
  bool _loadingEntry = false;
  Set<String> _entryDates = {};
  StreakInfo _streak = StreakInfo(current: 0, longest: 0);

  @override
  void initState() {
    super.initState();
    _refreshEntryDates();
  }

  void _refreshEntryDates() {
    final dates = StorageService.instance.allEntryDates();
    setState(() {
      _entryDates = dates.toSet();
      _streak = computeStreak(dates);
    });
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() { _selectedDay = day; _loadingEntry = true; _entryCtrl.text = ''; });
    final key = dateStr(day);
    final record = StorageService.instance.loadEntry(key);
    if (record != null) {
      try {
        final plain = await CryptoService.decrypt(widget.vaultKey, record.payload);
        _entryCtrl.text = plain;
      } catch (_) {
        _entryCtrl.text = '';
      }
    }
    setState(() => _loadingEntry = false);
  }

  Future<void> _saveEntry() async {
    if (_selectedDay == null) return;
    final key = dateStr(_selectedDay!);
    final text = _entryCtrl.text;

    if (text.trim().isEmpty) {
      await StorageService.instance.deleteEntry(key);
    } else {
      final payload = await CryptoService.encrypt(widget.vaultKey, text);
      await StorageService.instance.saveEntry(EntryRecord(date: key, payload: payload));
    }
    _refreshEntryDates();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${TimeOfDay.now().format(context)}'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14172B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14172B),
        elevation: 0,
        title: const Text('Keep', style: TextStyle(fontFamily: 'serif', color: Color(0xFFF6F1E4))),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2340),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF6B4E22)),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('${_streak.current}', style: const TextStyle(color: Color(0xFFF6F1E4), fontWeight: FontWeight.bold)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.lock, color: Color(0xFF8A8FB0)), onPressed: widget.onLock),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: const Color(0xFF1E2340),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selectedDay != null && dateStr(day) == dateStr(_selectedDay!),
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                _selectDay(selected);
              },
              onPageChanged: (focused) => _focusedDay = focused,
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Color(0xFFEDEAE2)),
                weekendTextStyle: const TextStyle(color: Color(0xFFEDEAE2)),
                outsideTextStyle: const TextStyle(color: Color(0xFF4A5080)),
                todayDecoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8A33D)), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Color(0xFFEDEAE2)),
                selectedDecoration: const BoxDecoration(color: Color(0xFFE8A33D), shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Color(0xFF0F1224), fontWeight: FontWeight.bold),
                markerDecoration: const BoxDecoration(color: Color(0xFFE8A33D), shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(color: Color(0xFFF6F1E4), fontSize: 16),
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF8A8FB0)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF8A8FB0)),
              ),
              eventLoader: (day) => _entryDates.contains(dateStr(day)) ? [true] : [],
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text('Pick a day, or write about today.', style: TextStyle(color: Color(0xFF8A8FB0))),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFF6F1E4), borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(20),
                      child: _loadingEntry
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _entryCtrl,
                                    maxLines: null,
                                    expands: true,
                                    style: const TextStyle(fontFamily: 'serif', fontSize: 16, color: Color(0xFF2B2418)),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Write freely. This is only for you.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _saveEntry,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A33D)),
                                  child: const Text('Save entry', style: TextStyle(color: Color(0xFF0F1224))),
                                ),
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
