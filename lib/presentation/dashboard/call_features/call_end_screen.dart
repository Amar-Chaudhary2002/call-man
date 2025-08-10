import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CallInteractionScreen extends StatefulWidget {
  const CallInteractionScreen({super.key});

  @override
  _CallInteractionScreenState createState() => _CallInteractionScreenState();
}

class _CallInteractionScreenState extends State<CallInteractionScreen> {
  String selectedNotification = 'push';
  TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // appBar: PreferredSize(
        //   preferredSize: Size.fromHeight(70.h),
        //   child: Container(
        //     decoration: BoxDecoration(
        //       color: Color(0xFF1E293B),
        //       border: Border(
        //         bottom: BorderSide(color: Color(0xFF475569), width: 1),
        //       ),
        //     ),
        //     child: SafeArea(
        //       child: Padding(
        //         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             Row(
        //               children: [
        //                 Icon(Icons.close, color: Colors.red, size: 20.sp),
        //                 SizedBox(width: 8.w),
        //                 Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   mainAxisAlignment: MainAxisAlignment.center,
        //                   children: [
        //                     Text(
        //                       'Call Ended',
        //                       style: GoogleFonts.poppins(
        //                         color: Colors.red,
        //                         fontWeight: FontWeight.w600,
        //                         fontSize: 14.sp,
        //                       ),
        //                     ),
        //                     Text(
        //                       '12:04-2:48 PM',
        //                       style: GoogleFonts.poppins(
        //                         color: Colors.grey[400],
        //                         fontSize: 12.sp,
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //               ],
        //             ),
        //             Icon(Icons.close, color: Colors.red, size: 20.sp),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Container(
            margin: EdgeInsets.only(top: 35),
            decoration: BoxDecoration(
              color: Color(0xFF1B2638),
              border: Border.all(color: Color(0xFFE5E7EB), width: 0.1.w),
              borderRadius: BorderRadius.circular(16),
            ),
            // padding: const EdgeInsets.only(left: 10, right: 12),
            alignment: Alignment.center,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset("assets/icons/call end.svg"),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Call Ended',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                '12:04-2:48 PM',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.close, color: Colors.red, size: 20.sp),
                    ],
                  ),
                ),
                Divider(color: Color(0xFFE5E7EB), thickness: 0.12),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    top: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information
                      _buildCustomerInfoSection(),
                      SizedBox(height: 16.h),

                      // Labels
                      _buildLabelsSection(),
                      SizedBox(height: 24.h),

                      // Set Reminder
                      _buildReminderSection(),
                      SizedBox(height: 24.h),

                      // Notes/Comments
                      _buildNotesSection(),
                      SizedBox(height: 24.h),

                      // Notification Options
                      _buildNotificationSection(),
                      SizedBox(height: 32.h),

                      // Save Button
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D394D),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.white, size: 16.sp),
              SizedBox(width: 5.w),
              Text(
                'Customer Information',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            offset: Offset(0, 10),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            offset: Offset(0, 4),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        // controller: controller,
                        // obscureText: obscureText,
                        // keyboardType: keyboardType,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "json",
                          hintStyle: GoogleFonts.roboto(
                            color: Colors.white70,
                            fontSize: 12.63,
                            fontWeight: FontWeight.w400,
                          ),
                          // suffixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 0.1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 0.1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 0.1,
                            ),
                          ),
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF475569),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(12.w),
                      child: Text(
                        '+1 (555) 123-4567',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              'Labels',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildLabel('VIP', Colors.orange),
            _buildLabel('Follow Up', Colors.blue),
            _buildAddLabelButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddLabelButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[500]!),
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, color: Colors.grey[300], size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            'Add Label',
            style: GoogleFonts.poppins(
              color: Colors.grey[300],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'Set Reminder',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildIconButton(Icons.calendar_today),
                SizedBox(width: 8.w),
                _buildIconButton(Icons.access_time),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF334155),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.all(20.w),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF475569),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                padding: EdgeInsets.all(8.w),
                child: Icon(Icons.add, color: Colors.grey[400], size: 16.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tap calendar or clock to set reminder',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF475569),
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(8.w),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'Notes/Comments *',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.edit, color: Colors.grey[400], size: 16.sp),
                SizedBox(width: 8.w),
                Icon(Icons.camera_alt, color: Colors.grey[400], size: 16.sp),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF334155),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.all(12.w),
          child: TextField(
            controller: notesController,
            maxLines: 3,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Add detailed notes about the interaction...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Notification Options',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Radio<String>(
                    value: 'push',
                    groupValue: selectedNotification,
                    onChanged: (value) {
                      setState(() {
                        selectedNotification = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Text(
                    'Push notification',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Radio<String>(
                    value: 'reminder',
                    groupValue: selectedNotification,
                    onChanged: (value) {
                      setState(() {
                        selectedNotification = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Text(
                    'Reminder call',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle save action
          print('Save interaction');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Save Interaction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
