import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';

class SchedulePsScreen extends StatefulWidget {
  const SchedulePsScreen({super.key});

  @override
  State<SchedulePsScreen> createState() => _SchedulePsScreenState();
}

class _SchedulePsScreenState extends State<SchedulePsScreen> {
  final _client = Supabase.instance.client;
  List<_ExamDate> _dates = [];
  Object? _selectedScheduleId;
  Object? _registeredScheduleId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppState.currentUser.addListener(_onUserChanged);
    _loadSchedules();
  }

  @override
  void dispose() {
    AppState.currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() => _loadSchedules();

  Future<void> _loadSchedules() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final schedules = await _client
          .from('ps_examdate')
          .select('sched_id, date, max_examinee, room, batch')
          .order('date');
      final registrations = await _client
          .from('ps_user_sched')
          .select('user_id, registered_at, batch, room');
      final registrationRows = registrations
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final counts = <String, int>{};
      for (final row in registrationRows) {
        final key = _registrationKey(row['batch'], row['room']);
        counts[key] = (counts[key] ?? 0) + 1;
      }
      Object? currentUserId;
      final username = AppState.currentUser.value;
      if (username != null && username.isNotEmpty) {
        final account = await _client
            .from('user_acc')
            .select('id')
            .eq('username', username)
            .maybeSingle();
        currentUserId = account?['id'];
      }
      final parsed = <_ExamDate>[];
      for (final raw in schedules) {
        final row = Map<String, dynamic>.from(raw);
        final date = DateTime.tryParse(row['date']?.toString() ?? '');
        if (date == null) continue;
        final key = _registrationKey(row['batch'], row['room']);
        parsed.add(
          _ExamDate(
            id: row['sched_id'],
            date: date,
            capacity: int.tryParse(row['max_examinee']?.toString() ?? '') ?? 0,
            room: row['room']?.toString() ?? '',
            batch: row['batch']?.toString() ?? '',
            registered: counts[key] ?? 0,
          ),
        );
      }
      parsed.sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() {
        _dates = parsed;
        final registration = registrationRows
            .where(
              (row) => row['user_id']?.toString() == currentUserId?.toString(),
            )
            .firstOrNull;
        _registeredScheduleId = registration == null
            ? null
            : parsed
                  .where(
                    (d) =>
                        _registrationKey(d.batch, d.room) ==
                        _registrationKey(
                          registration['batch'],
                          registration['room'],
                        ),
                  )
                  .firstOrNull
                  ?.id;
        _selectedScheduleId = parsed.where((d) => !d.isFull).firstOrNull?.id;
        _loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load exam schedules. $e';
        });
    }
  }

  String _registrationKey(Object? batch, Object? room) =>
      '${batch?.toString().trim().toLowerCase() ?? ''}|${room?.toString().trim().toLowerCase() ?? ''}';

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _register() async {
    if (_submitting) return;
    final selected = _dates
        .where((d) => d.id == _selectedScheduleId)
        .firstOrNull;
    final username = AppState.currentUser.value;
    if (selected == null || username == null || username.isEmpty) {
      _message('Please sign in and choose an available exam date.');
      return;
    }
    if (selected.isFull) {
      _message('This exam date is full.');
      await _loadSchedules();
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = await _client
          .from('user_acc')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (user == null || user['id'] == null)
        throw Exception('Could not find your user account.');
      final existing = await _client
          .from('ps_user_sched')
          .select('reg_id')
          .eq('user_id', user['id'])
          .maybeSingle();
      if (existing != null) {
        _message('You already have an exam registration.');
      } else {
        await _client.from('ps_user_sched').insert({
          'registered_at': DateTime.now().toIso8601String(),
          'user_id': user['id'],
          'batch': selected.batch,
          'room': selected.room,
        });
        _message('Your exam date is registered.');
      }
      await _loadSchedules();
    } catch (e) {
      _message('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reschedule() async {
    final username = AppState.currentUser.value;
    final next = _dates.where((d) => d.id == _selectedScheduleId).firstOrNull;
    if (username == null || next == null || next.isFull) {
      _message('Select an available Saturday first.');
      return;
    }
    if (next.id == _registeredScheduleId) {
      _message('This is already your registered exam date.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final account = await _client
          .from('user_acc')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (account == null || account['id'] == null) {
        throw Exception('Could not find your user account.');
      }
      await _client
          .from('ps_user_sched')
          .update({
            'registered_at': DateTime.now().toIso8601String(),
            'batch': next.batch,
            'room': next.room,
          })
          .eq('user_id', account['id']);
      _message('Your exam date was rescheduled.');
      await _loadSchedules();
    } catch (e) {
      _message('Reschedule failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openVenueMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/place/Universidad+de+Dagupan/@16.0507174,120.3382644,17z/data=!3m1!4b1!4m6!3m5!1s0x339167fd0100bfa3:0x392d5ed47cf7639e!8m2!3d16.0507123!4d120.3408393!16s%2Fm%2F063z73b?entry=ttu&g_ep=EgoyMDI2MTAwNy4wIKXMDSoASAFQAw%3D%3D',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _message('Could not open Google Maps.');
    }
  }

  Widget _mapPreview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 2, bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Exam Venue Map',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      Container(
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0E9),
          border: Border.all(color: const Color(0xFF252525), width: 1.4),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF181818),
              offset: Offset(2, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child:
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
            ? GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(16.0507123, 120.3408393),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('universidad_de_dagupan'),
                    position: LatLng(16.0507123, 120.3408393),
                    infoWindow: InfoWindow(title: 'Universidad de Dagupan'),
                  ),
                },
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    const Text('Universidad de Dagupan'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openVenueMap,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open Google Maps'),
                    ),
                  ],
                ),
              ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final selected = _dates
        .where((d) => d.id == _selectedScheduleId)
        .firstOrNull;
    final registered = _dates
        .where((d) => d.id == _registeredScheduleId)
        .firstOrNull;
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDFB9),
                      border: Border.all(
                        color: const Color(0xFF252525),
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 17,
                          color: Color(0xFF8E5100),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'All exams are Saturdays only. Make sure to bring important documents.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF32251B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  registered != null
                      ? _confirmedCard(registered)
                      : _notScheduledCard(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(
                        Icons.view_column_outlined,
                        color: AppColors.primary,
                        size: 19,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Presidential Scholar Exam Dates',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_dates.isEmpty) _emptyState() else _buildDateGrid(),
                  const SizedBox(height: 24),
                  _actionCard(
                    Icons.update,
                    'Reschedule Slot',
                    'Saturdays only',
                    const Color(0xFFFFD7AA),
                    () {
                      if (registered != null) {
                        _reschedule();
                      } else if (selected != null) {
                        _register();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _mapPreview(),
                  const SizedBox(height: 20),
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF252525),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateGrid() {
    // Every date shown here comes directly from ps_examdate.
    final days = _dates;
    if (days.isEmpty) return _emptyState();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.id == _selectedScheduleId;
          final disabled = day.isFull;
          final color = disabled
              ? const Color(0xFFFFF1F1)
              : isSelected
              ? AppColors.primary
              : Colors.white;
          final textColor = isSelected && !disabled
              ? Colors.white
              : const Color(0xFF20243A);
          return InkWell(
            onTap: disabled
                ? null
                : () {
                    setState(() => _selectedScheduleId = day.id);
                    if (_registeredScheduleId == null) _register();
                  },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 84,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: disabled
                      ? const Color(0xFFFFC7C7)
                      : isSelected
                      ? AppColors.primary
                      : const Color(0xFFE4E1DD),
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(2, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthName(day.date.month).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: .6,
                      fontWeight: FontWeight.w800,
                      color: textColor.withValues(alpha: .7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _weekday(day.date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: .75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: disabled
                          ? const Color(0xFFF04444)
                          : const Color(0xFF16864A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      disabled ? 'FULL' : '${day.remaining} LEFT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _notScheduledCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        Icon(Icons.event_busy_outlined, color: AppColors.textSecondary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'You are not scheduled for an exam.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _confirmedCard(_ExamDate date) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFF171717), width: 1.5),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFF181818),
          offset: Offset(3, 4),
          blurRadius: 0,
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF0756C9),
          child: const Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CONFIRMED REGISTRATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'CONFIRMED',
                style: TextStyle(
                  color: Color(0xFFFFD39A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PHASE ONE',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF606574),
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Presidential Scholar Exam',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4F7),
                  border: Border.all(
                    color: const Color(0xFF34313A),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_weekday(date.date.weekday)}, ${_monthName(date.date.month)} ${date.date.day}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Exam schedule',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Venue',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            date.room,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Batch ${date.batch}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF292929))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      'ENTRY VERIFICATION',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF666666),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF292929))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0F2),
                      border: Border.all(
                        color: const Color(0xFF222222),
                        width: 1.3,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 24),
                        Text(
                          'TAP QR',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _message('Your entry slip is ready.'),
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text(
                        'View Entry Slip & Pass',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0756C9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 105,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF171717), width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF181818),
            offset: Offset(2, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: iconColor,
              border: Border.all(color: const Color(0xFF222222), width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _selectionCard(_ExamDate date) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          offset: Offset(3, 4),
          blurRadius: 0,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available, color: AppColors.primary),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'SELECTED EXAM DATE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${date.remaining} spots left',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16864A),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Text(
          '${_weekday(date.date.weekday)}, ${_monthName(date.date.month)} ${date.date.day}, ${date.date.year}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          'Batch ${date.batch}  •  Room ${date.room}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '${date.registered} of ${date.capacity} examinees registered',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _register,
            icon: _submitting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.how_to_reg),
            label: Text(
              _submitting ? 'Registering…' : 'Register for this date',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptySelection() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'There are no available exam dates right now. Please check again later.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'No exam dates are available right now.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
  String _weekday(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}

class _ExamDate {
  const _ExamDate({
    required this.id,
    required this.date,
    required this.capacity,
    required this.room,
    required this.batch,
    required this.registered,
  });
  final Object? id;
  final DateTime date;
  final int capacity;
  final String room;
  final String batch;
  final int registered;
  bool get isFull => capacity <= 0 || registered >= capacity;
  int get remaining => (capacity - registered).clamp(0, capacity);
}
