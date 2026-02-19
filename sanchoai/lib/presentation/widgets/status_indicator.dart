import 'package:flutter/material.dart';
import '../../domain/entities/model_state.dart';

class StatusIndicator extends StatelessWidget {
  final ModelState modelState;
  final bool showProgress;

  const StatusIndicator({
    super.key,
    required this.modelState,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBackgroundColor().withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBackgroundColor().withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getBackgroundColor(),
              letterSpacing: 0.3,
            ),
          ),
          if (showProgress && modelState.status == ModelStatus.loading) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getBackgroundColor()),
              ),
            ),
          ],
          if (modelState.status == ModelStatus.loading && modelState.progress > 0) ...[
            const SizedBox(width: 6),
            Text(
              '${(modelState.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getBackgroundColor().withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (modelState.status) {
      case ModelStatus.idle:
        return Icon(
          Icons.circle_outlined,
          size: 14,
          color: _getBackgroundColor(),
        );
      case ModelStatus.loading:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getBackgroundColor()),
          ),
        );
      case ModelStatus.ready:
        return Icon(
          Icons.check_circle,
          size: 14,
          color: _getBackgroundColor(),
        );
      case ModelStatus.generating:
        return _PulsingIcon(color: _getBackgroundColor());
      case ModelStatus.error:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: _getBackgroundColor(),
        );
    }
  }

  Color _getBackgroundColor() {
    switch (modelState.status) {
      case ModelStatus.idle:
        return Colors.grey.shade600;
      case ModelStatus.loading:
        return Colors.amber.shade600;
      case ModelStatus.ready:
        return Colors.green.shade600;
      case ModelStatus.generating:
        return Colors.blue.shade600;
      case ModelStatus.error:
        return Colors.red.shade600;
    }
  }

  String _getStatusText() {
    switch (modelState.status) {
      case ModelStatus.idle:
        return 'No Model';
      case ModelStatus.loading:
        return 'Loading';
      case ModelStatus.ready:
        return 'Ready';
      case ModelStatus.generating:
        return 'Thinking';
      case ModelStatus.error:
        return 'Error';
    }
  }
}

class _PulsingIcon extends StatefulWidget {
  final Color color;

  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(
            Icons.auto_awesome,
            size: 14,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class CompactStatusIndicator extends StatelessWidget {
  final ModelState modelState;

  const CompactStatusIndicator({
    super.key,
    required this.modelState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColor(),
              boxShadow: [
                BoxShadow(
                  color: _getColor().withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getText(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (modelState.status) {
      case ModelStatus.idle:
        return Colors.grey;
      case ModelStatus.loading:
        return Colors.orange;
      case ModelStatus.ready:
        return Colors.green;
      case ModelStatus.generating:
        return Colors.blue;
      case ModelStatus.error:
        return Colors.red;
    }
  }

  String _getText() {
    switch (modelState.status) {
      case ModelStatus.idle:
        return 'Offline';
      case ModelStatus.loading:
        return 'Loading';
      case ModelStatus.ready:
        return 'Online';
      case ModelStatus.generating:
        return 'Active';
      case ModelStatus.error:
        return 'Error';
    }
  }
}
