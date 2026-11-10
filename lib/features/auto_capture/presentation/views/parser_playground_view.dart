import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/providers/app_alert_provider.dart';
import '../../domain/models/parsed_transaction.dart';
import '../../domain/parsing/sms_transaction_parser.dart';
import '../view_models/capture_inbox_view_model.dart';

class ParserPlaygroundView extends ConsumerStatefulWidget {
  const ParserPlaygroundView({super.key});

  @override
  ConsumerState<ParserPlaygroundView> createState() =>
      _ParserPlaygroundViewState();
}

class _ParserPlaygroundViewState extends ConsumerState<ParserPlaygroundView> {
  final TextEditingController _controller = TextEditingController();
  final SmsTransactionParser _parser = const SmsTransactionParser();
  ParseResult? _result;
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _result = null);
      return;
    }

    final res = _parser.parse(text, DateTime.now());
    setState(() => _result = res);
  }

  Future<void> _addAsPending() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _result is! ParsedTransaction) return;

    setState(() => _isAdding = true);
    await ref
        .read(captureInboxViewModelProvider.notifier)
        .ingestManualMessage(text);

    if (mounted) {
      setState(() => _isAdding = false);
      ref
          .read(appAlertProvider.notifier)
          .show(
            'Transaction added to capture inbox!',
            tone: AppAlertTone.success,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Parser Playground')),
      body: FadingScrollBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste a bank SMS below to test the parser. Message text remains in memory and is never logged or stored without parsing.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Paste SMS message here...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withAlpha(80),
                ),
                onChanged: (_) => _parse(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _parse,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Parse'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() => _result = null);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_result != null) _buildResultCard(context, _result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ParseResult result) {
    final theme = Theme.of(context);

    if (result is NotATransaction) {
      return Card(
        color: theme.colorScheme.errorContainer.withAlpha(90),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Not a valid transaction',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${result.reason}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final parsed = result as ParsedTransaction;
    final isExpense = parsed.type.isExpense;
    final typeColor = isExpense
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction Detected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    parsed.confidence == ParseConfidence.high
                        ? 'High Confidence'
                        : 'Medium Confidence',
                    style: TextStyle(
                      fontSize: 11,
                      color: parsed.confidence == ParseConfidence.high
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildFieldRow(
              'Amount',
              CurrencyFormatter.formatCents(
                parsed.amountCents,
                ref.watch(selectedCurrencyProvider),
              ),
              valueColor: typeColor,
            ),
            _buildFieldRow('Type', parsed.type.label, valueColor: typeColor),
            _buildFieldRow(
              'Counterparty',
              parsed.counterparty ?? 'Bank transaction',
            ),
            _buildFieldRow(
              'Account Last 4',
              parsed.accountLast4 != null
                  ? '•••• ${parsed.accountLast4}'
                  : 'Not found',
            ),
            _buildFieldRow(
              'Reference / Txn ID',
              parsed.reference ?? 'Not found',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _isAdding ? null : _addAsPending,
                icon: const Icon(Icons.inbox_outlined),
                label: _isAdding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to Review Inbox'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
