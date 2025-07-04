// lib/features/calendar/presentation/screens/edit_event_screen.dart
import 'package:flutter/material.dart';
import '../../domain/entities/event.dart';

class EditEventScreen extends StatefulWidget {
  final Event? event;

  const EditEventScreen({super.key, this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _titleController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _startTime = TimeOfDay(
        hour: int.parse(widget.event!.startTime.split(':')[0]),
        minute: int.parse(widget.event!.startTime.split(':')[1]),
      );
      _endTime = TimeOfDay(
        hour: int.parse(widget.event!.endTime.split(':')[0]),
        minute: int.parse(widget.event!.endTime.split(':')[1]),
      );
    } else {
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null && picked != (isStartTime ? _startTime : _endTime)) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    if (enteredTitle.isEmpty) return;

    final result = {
      'title': enteredTitle,
      'startTime':
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Tambah Acara' : 'Edit Acara'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(labelText: 'Judul Acara'),
              controller: _titleController,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waktu Mulai: ${MaterialLocalizations.of(context).formatTimeOfDay(_startTime)}',
                ),
                TextButton(
                  onPressed: () => _selectTime(context, true),
                  child: const Text('Pilih Waktu'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waktu Selesai: ${MaterialLocalizations.of(context).formatTimeOfDay(_endTime)}',
                ),
                TextButton(
                  onPressed: () => _selectTime(context, false),
                  child: const Text('Pilih Waktu'),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}
