import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Booking Notifications
  bool _bookingConfirmations = true;
  bool _bookingReminders = true;
  bool _cancellations = true;
  bool _modifications = true;

  // Messages
  bool _newMessages = true;
  bool _messageReplies = true;

  // Promotions & Updates
  bool _specialOffers = true;
  bool _newProperties = false;
  bool _priceDrops = true;
  bool _newsletter = false;

  // Account Activity
  bool _accountUpdates = true;
  bool _securityAlerts = true;
  bool _paymentNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.charcoal, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage how you receive notifications from Houseiana',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Booking Notifications
          const Text(
            'Booking Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Booking Confirmations',
            'Get notified when a booking is confirmed',
            _bookingConfirmations,
            (value) => setState(() => _bookingConfirmations = value),
          ),
          _buildSwitchTile(
            'Booking Reminders',
            'Reminders before check-in and check-out',
            _bookingReminders,
            (value) => setState(() => _bookingReminders = value),
          ),
          _buildSwitchTile(
            'Cancellations',
            'Notifications about booking cancellations',
            _cancellations,
            (value) => setState(() => _cancellations = value),
          ),
          _buildSwitchTile(
            'Modifications',
            'Updates about booking changes',
            _modifications,
            (value) => setState(() => _modifications = value),
          ),

          const SizedBox(height: 32),

          // Messages
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'New Messages',
            'Notifications for new messages',
            _newMessages,
            (value) => setState(() => _newMessages = value),
          ),
          _buildSwitchTile(
            'Message Replies',
            'When hosts reply to your messages',
            _messageReplies,
            (value) => setState(() => _messageReplies = value),
          ),

          const SizedBox(height: 32),

          // Promotions & Updates
          const Text(
            'Promotions & Updates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Special Offers',
            'Exclusive deals and promotions',
            _specialOffers,
            (value) => setState(() => _specialOffers = value),
          ),
          _buildSwitchTile(
            'New Properties',
            'Alerts about new listings in your area',
            _newProperties,
            (value) => setState(() => _newProperties = value),
          ),
          _buildSwitchTile(
            'Price Drops',
            'Notifications when prices drop on saved properties',
            _priceDrops,
            (value) => setState(() => _priceDrops = value),
          ),
          _buildSwitchTile(
            'Newsletter',
            'Monthly newsletter with tips and updates',
            _newsletter,
            (value) => setState(() => _newsletter = value),
          ),

          const SizedBox(height: 32),

          // Account Activity
          const Text(
            'Account Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Account Updates',
            'Important updates about your account',
            _accountUpdates,
            (value) => setState(() => _accountUpdates = value),
          ),
          _buildSwitchTile(
            'Security Alerts',
            'Alerts about account security',
            _securityAlerts,
            (value) => setState(() => _securityAlerts = value),
          ),
          _buildSwitchTile(
            'Payment Notifications',
            'Updates about payments and refunds',
            _paymentNotifications,
            (value) => setState(() => _paymentNotifications = value),
          ),

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
