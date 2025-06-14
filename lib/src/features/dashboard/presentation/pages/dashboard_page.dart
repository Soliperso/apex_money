import 'package:flutter/material.dart';
import 'package:apex_money/src/features/auth/presentation/pages/profile_screen.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Income: Placeholder',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    Text(
                      'Total Expenses: Placeholder',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    Text(
                      'Net Savings: Placeholder',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Your Transactions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Replace with dynamic data
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Transaction $index',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    subtitle: Text(
                      'Details for transaction $index',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Goals:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Replace with dynamic data
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Goal $index',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    subtitle: Text(
                      'Details for goal $index',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Insights:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 2, // Replace with dynamic data
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Insight $index',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    subtitle: Text(
                      'Details for insight $index',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'AI Insights',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        onTap: (index) {
          switch (index) {
            case 0:
              GoRouter.of(context).go('/dashboard');
              break;
            case 1:
              GoRouter.of(context).go('/transactions');
              break;
            case 2:
              GoRouter.of(context).go('/groups');
              break;
            case 3:
              GoRouter.of(context).go('/ai-insights');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/create-transaction');
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Transaction',
      ),
    );
  }
}
