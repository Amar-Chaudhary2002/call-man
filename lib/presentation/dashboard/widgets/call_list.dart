import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CallTile extends StatelessWidget {
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

  Color _getCallTypeTextColor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains("missed") ||
        lowerType.contains("declined") ||
        lowerType.contains("not picked")) {
      return Color(0xFFF56E0B);
    } else if (lowerType.contains("incoming")) {
      return Color(0xFF5498F7);
    } else if (lowerType.contains("outgoing")) {
      return Color(0xFF10B981);
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.1.w),
        ),
        margin: EdgeInsets.only(bottom: 14.h),
        child: ListTile(
          contentPadding: EdgeInsets.only(left: 12, right: 5),
          leading: CircleAvatar(
            backgroundColor: backgroundColor,
            radius: 20,
            child: SvgPicture.asset(
              svgAsset,
              color: iconColor,
              width: 20,
              height: 20,
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            number,
            style: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
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
                    time,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    duration != null && duration!.isNotEmpty
                        ? "$callType • $duration"
                        : callType,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: _getCallTypeTextColor(callType),
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
                  constraints: BoxConstraints(minHeight: 25, minWidth: 25),
                  icon: Icon(
                    Icons.more_vert,
                    color: Color(0xFF9CA3AF),
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
    );
  }
}
