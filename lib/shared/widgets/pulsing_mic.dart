import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A large, tappable microphone button that emits animated ripples while
/// recording. Drives the F2/F4 capture screen's "tap to talk" affordance.
class PulsingMic extends StatefulWidget {
  const PulsingMic({
    super.key,
    required this.recording,
    required this.onTap,
    this.busy = false,
    this.size = 132,
  });

  final bool recording;
  final bool busy;
  final VoidCallback onTap;
  final double size;

  @override
  State<PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<PulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulsingMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.recording && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.7,
      height: widget.size * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (widget.recording)
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _ripple(_controller.value),
                    _ripple((_controller.value + 0.5) % 1),
                  ],
                );
              },
            ),
          GestureDetector(
            onTap: widget.busy ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.recording
                      ? const <Color>[AppColors.negative, Color(0xFFB91C1C)]
                      : AppColors.logoGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (widget.recording ? AppColors.negative : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: widget.busy
                  ? const Padding(
                      padding: EdgeInsets.all(44),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: widget.size * 0.42,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ripple(double t) {
    return Container(
      width: widget.size + (widget.size * 0.7 * t),
      height: widget.size + (widget.size * 0.7 * t),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.negative.withOpacity((1 - t) * 0.18),
      ),
    );
  }
}
