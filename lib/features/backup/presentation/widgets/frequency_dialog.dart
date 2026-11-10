import 'package:flutter/material.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../domain/models/auto_backup_frequency.dart';

class FrequencyDialog extends StatelessWidget {
  final AutoBackupFrequency currentFrequency;
  final ValueChanged<AutoBackupFrequency> onSelected;

  const FrequencyDialog({
    super.key,
    required this.currentFrequency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Automatic backup frequency'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: FadingScrollBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AutoBackupFrequency.values.map((freq) {
              return RadioListTile<AutoBackupFrequency>(
                title: Text(freq.label),
                value: freq,
                // ignore: deprecated_member_use
                groupValue: currentFrequency,
                // ignore: deprecated_member_use
                onChanged: (selected) {
                  if (selected != null) {
                    onSelected(selected);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
