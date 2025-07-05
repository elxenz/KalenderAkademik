import 'package:flutter/material.dart';

// Enum untuk merepresentasikan setiap jenis tampilan
enum CalendarView { week, month, agenda } // Hapus 'day' dari sini

class AppDrawer extends StatelessWidget {
  final Function(CalendarView) onTampilanSelected;

  const AppDrawer({super.key, required this.onTampilanSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text("Kalender",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text("Aplikasi Kalender Pribadi"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.calendar_month, size: 40.0, color: Colors.blue),
            ),
            decoration: BoxDecoration(color: Colors.blue),
          ),
          // ListTile untuk Tampilan Hari telah dihapus
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: const Text('Tampilan Minggu'),
            onTap: () => onTampilanSelected(CalendarView.week),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Tampilan Bulan'),
            onTap: () => onTampilanSelected(CalendarView.month),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.view_agenda_outlined),
            title: const Text('Agenda'),
            onTap: () => onTampilanSelected(CalendarView.agenda),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Pengaturan akan datang!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
