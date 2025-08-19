import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CallTile extends StatefulWidget {
  final String name;
  final String number;
  final String time;
  final String callType;
  final String? duration;
  final String svgAsset;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const CallTile({
    super.key,
    required this.name,
    required this.number,
    required this.time,
    required this.callType,
    this.duration,
    required this.svgAsset,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  State<CallTile> createState() => _CallTileState();
}

class _CallTileState extends State<CallTile>
    with SingleTickerProviderStateMixin {
  static const double _swipeThreshold = 60;
  static const double _maxSwipeDistance = 120;
  late AnimationController _animationController;
  double _dragExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    // Clean the phone number - remove all non-digit characters
    final cleanNumber = widget.number.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = 'https://wa.me/$cleanNumber';

    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackbar('Could not launch WhatsApp');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _onDragEnd() {
    if (_dragExtent.abs() > _swipeThreshold) {
      if (_dragExtent > 0) {
        // Swiped right - call
        widget.onTap?.call();
      } else {
        // Swiped left - WhatsApp
        _launchWhatsApp();
      }
    }
    // Animate back to center
    _animationController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _dragExtent = 0;
  }

  Color _getCallTypeTextColor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains("missed") ||
        lowerType.contains("declined") ||
        lowerType.contains("not picked")) {
      return const Color(0xFFF56E0B);
    } else if (lowerType.contains("incoming")) {
      return const Color(0xFF5498F7);
    } else if (lowerType.contains("outgoing")) {
      return const Color(0xFF10B981);
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent = (_dragExtent + details.primaryDelta!).clamp(
            -_maxSwipeDistance,
            _maxSwipeDistance,
          );
        });
      },
      onHorizontalDragEnd: (_) => _onDragEnd(),
      child: Transform.translate(
        offset: Offset(_dragExtent, 0),
        child: Stack(
          children: [
            // Background actions
            if (_dragExtent.abs() > 0)
              Positioned.fill(
                child: Container(
                  color: _dragExtent > 0
                      ? Colors.green.withOpacity(
                          0.3 * (_dragExtent / _maxSwipeDistance),
                        )
                      : const Color(0xFF25D366).withOpacity(
                          0.3 * (_dragExtent.abs() / _maxSwipeDistance),
                        ),
                  child: Align(
                    alignment: _dragExtent > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Icon(
                        _dragExtent > 0 ? Icons.phone : Icons.chat,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ),
            // Main content
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 0.1.w,
                ),
                color: const Color(0xFF1E293B),
              ),
              margin: EdgeInsets.only(bottom: 14.h),
              child: ListTile(
                contentPadding: EdgeInsets.only(left: 12, right: 5),
                leading: CircleAvatar(
                  backgroundColor: widget.backgroundColor,
                  radius: 20,
                  child: SvgPicture.asset(
                    widget.svgAsset,
                    color: widget.iconColor,
                    width: 20,
                    height: 20,
                  ),
                ),
                title: Text(
                  widget.name,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.number,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.time,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.duration != null && widget.duration!.isNotEmpty
                              ? "${widget.callType} • ${widget.duration}"
                              : widget.callType,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: _getCallTypeTextColor(widget.callType),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 5.w),
                    SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minHeight: 25,
                          minWidth: 25,
                        ),
                        icon: Icon(
                          Icons.more_vert,
                          color: const Color(0xFF9CA3AF),
                          size: 18.sp,
                        ),
                        onPressed: () {
                          // TODO: Add your menu action
                        },
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
