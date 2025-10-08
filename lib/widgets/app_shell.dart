import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final String title;
  final List<Widget>? actions;
  final bool hideBack;

  const AppShell({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.title = '',
    this.actions,
    this.hideBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        automaticallyImplyLeading: !hideBack,
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 0)
            Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
          if (i == 1)
            Navigator.pushNamedAndRemoveUntil(context, '/groups', (r) => false);
          if (i == 2)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/settings',
              (r) => false,
            );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
