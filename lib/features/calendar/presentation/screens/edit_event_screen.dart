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
  final _descController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  bool _isRecurring = false;
  RecurrenceRule _recurrenceRule = RecurrenceRule.daily;

  final List<Color> _colorPalette = [
    Colors.blue.shade700,
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.teal.shade700,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descController.text = widget.event!.description;
      _selectedColor = widget.event!.color;
      _startTime = TimeOfDay(
          hour: int.parse(widget.event!.startTime.split(':')[0]),
          minute: int.parse(widget.event!.startTime.split(':')[1]));
      _endTime = TimeOfDay(
          hour: int.parse(widget.event!.endTime.split(':')[0]),
          minute: int.parse(widget.event!.endTime.split(':')[1]));
      _isRecurring = widget.event!.isRecurring;
      _recurrenceRule = widget.event!.recurrenceRule;
    } else {
      _selectedColor = _colorPalette.first;
      _startTime = TimeOfDay.now();
      _endTime =
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    if (enteredTitle.isEmpty) return;

    final result = {
      'title': enteredTitle,
      'description': _descController.text,
      'startTime':
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      // ignore: deprecated_member_use_from_same_package
      'colorValue': _selectedColor.value,
      'isRecurring': _isRecurring,
      'recurrenceRule': _isRecurring ? _recurrenceRule : RecurrenceRule.none,
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.event == null ? 'Tambah Acara' : 'Edit Acara')),
      backgroundColor: _selectedColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(labelText: 'Judul Acara'),
              controller: _titleController,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Deskripsi (Opsional)'),
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Acara Berulang'),
              value: _isRecurring,
              onChanged: (bool value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring)
              DropdownButtonFormField<RecurrenceRule>(
                value: _recurrenceRule,
                decoration: const InputDecoration(labelText: 'Ulangi setiap'),
                items: const [
                  DropdownMenuItem(
                      value: RecurrenceRule.daily, child: Text('Hari')),
                  DropdownMenuItem(
                      value: RecurrenceRule.weekly, child: Text('Minggu')),
                  DropdownMenuItem(
                      value: RecurrenceRule.monthly, child: Text('Bulan')),
                ],
                onChanged: (RecurrenceRule? newValue) {
                  setState(() {
                    _recurrenceRule = newValue!;
                  });
                },
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Waktu Mulai: ${MaterialLocalizations.of(context).formatTimeOfDay(_startTime)}'),
                TextButton(
                  onPressed: () => _selectTime(context, true),
                  child: const Text('Pilih'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Waktu Selesai: ${MaterialLocalizations.of(context).formatTimeOfDay(_endTime)}'),
                TextButton(
                  onPressed: () => _selectTime(context, false),
                  child: const Text('Pilih'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Warna Acara:"),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorPalette.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('Simpan Acara'),
            ),
          ],
        ),
      ),
    );
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
}
