import 'package:flutter/material.dart';

class CallList extends StatelessWidget {
  const CallList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(title: "Today"),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Outgoing",
          duration: "25 min",
          icon: Icons.call_made,
          iconColor: Colors.green,
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Incoming",
          duration: "8 min",
          icon: Icons.call_received,
          iconColor: Colors.blue,
        ),
        // More call tiles...
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class CallTile extends StatelessWidget {
  final String name;
  final String number;
  final String time;
  final String callType;
  final String? duration;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const CallTile({
    super.key,
    required this.name,
    required this.number,
    required this.time,
    required this.callType,
    this.duration,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF25316D),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            Text(
              duration != null ? "$callType • $duration" : callType,
              style: TextStyle(
                color:
                    callType.toLowerCase().contains("missed") ||
                        callType.toLowerCase().contains("declined")
                    ? Colors.redAccent
                    : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
