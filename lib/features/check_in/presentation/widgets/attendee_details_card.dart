import 'package:event_scan/features/check_in/domain/entities/attendee.dart';
import 'package:flutter/material.dart';

class AttendeeDetailsCard extends StatelessWidget {
  const AttendeeDetailsCard({super.key, required this.attendee});

  final Attendee attendee;

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendee.checkIn == true;
    final statusText = isCheckedIn ? 'Ya realizo check-in' : 'Pendiente de check-in';
    final statusColor = isCheckedIn ? Colors.green.shade700 : Colors.orange.shade700;

    final items = <MapEntry<String, String>>[
      MapEntry('RUT', attendee.rut),
      MapEntry('Email', attendee.email),
      MapEntry('Teléfono', attendee.telefono),
      MapEntry('Distrito', attendee.distrito),
      MapEntry('Iglesia', attendee.iglesia),
      MapEntry('Taller AM', attendee.tallerAm),
      MapEntry('Taller PM', attendee.tallerPm),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendee.fullName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isCheckedIn ? Icons.verified : Icons.schedule,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
