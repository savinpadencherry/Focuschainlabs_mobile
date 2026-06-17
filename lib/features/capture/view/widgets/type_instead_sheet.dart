import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../bloc/capture_flow_bloc.dart';

/// Typed fallback entry (F4: typing is a fallback, never the default). Presented
/// as a modal sheet so the mic stays the primary affordance.
class TypeInsteadSheet {
  static Future<void> show(BuildContext context) {
    final CaptureFlowBloc bloc = context.read<CaptureFlowBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (BuildContext sheetContext) => BlocProvider<CaptureFlowBloc>.value(
        value: bloc,
        child: const _TypeInsteadBody(),
      ),
    );
  }
}

class _TypeInsteadBody extends StatefulWidget {
  const _TypeInsteadBody();

  @override
  State<_TypeInsteadBody> createState() => _TypeInsteadBodyState();
}

class _TypeInsteadBodyState extends State<_TypeInsteadBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<CaptureFlowBloc>().add(CaptureManualSubmitted(text));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Type your note', style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.vGapMd,
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'e.g. Called Acme, revised quote by Friday, deal warm.',
            ),
          ),
          AppSpacing.vGapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Extract update'),
            ),
          ),
        ],
      ),
    );
  }
}
