import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import 'login_page.dart';
import 'proposal_page.dart';
import 'event_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  bool _isCommittee = false;

  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];
  List<dynamic> _popularEvents = [];
  String _userName = '...';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      _handleLogout();
      return;
    }

    try {
      final userResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final committeeResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/check-committee'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final feedResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/feed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (userResponse.statusCode == 200 && feedResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final committeeData = jsonDecode(committeeResponse.body);
        final feedData = jsonDecode(feedResponse.body);

        setState(() {
          String fullName = userData['name'] ?? 'Mahasiswa';
          _userName = fullName.split(' ')[0];
          _isCommittee = committeeData['is_committee'] ?? false;

          if (userData['avatar'] != null) {
            final String baseUrlImage = ApiConstants.baseUrl.replaceAll(
              '/api',
              '',
            );
            _avatarUrl = '$baseUrlImage/storage/${userData['avatar']}';
          }

          _events = feedData['data'] ?? [];
          _filteredEvents = List.from(_events);

          _popularEvents = List.from(_events);
          _popularEvents.sort((a, b) {
            double capA = (a['capacity'] ?? 1).toDouble();
            double regA = (a['registrations_count'] ?? 0).toDouble();
            double pctA = regA / (capA == 0 ? 1 : capA);

            double capB = (b['capacity'] ?? 1).toDouble();
            double regB = (b['registrations_count'] ?? 0).toDouble();
            double pctB = regB / (capB == 0 ? 1 : capB);

            return pctB.compareTo(pctA);
          });

          if (_popularEvents.length > 3) {
            _popularEvents = _popularEvents.sublist(0, 3);
          }

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = List.from(_events);
    } else {
      results = _events
          .where(
            (event) => event['title'].toString().toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }
    setState(() => _filteredEvents = results);
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  String _getOrganizationName(dynamic event) {
    if (event['panitia'] != null) {
      return event['panitia']['organization'] ??
          event['panitia']['name'] ??
          'Penyelenggara';
    }
    return event['organization_name'] ?? 'Penyelenggara';
  }

  Widget _buildHorizontalCard(dynamic event) {
    String orgName = _getOrganizationName(event);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.celebration, size: 40, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Nama Acara',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blackTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orgName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'] ??
                              (event['is_online'] == 1 ? 'Online' : 'Offline'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.greyTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(dynamic event) {
    String orgName = _getOrganizationName(event);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event,
                color: AppColors.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Nama Acara',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blackTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orgName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.greyTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sisa Kuota: ${((event['capacity'] ?? 0) - (event['registrations_count'] ?? 0)).clamp(0, 9999)}',
                        style: const TextStyle(
                          color: AppColors.greyTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      floatingActionButton: _isCommittee
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProposalPage()),
              ),
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajukan Acara',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              )
            : RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: AppColors.cardColor,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $_userName 👋',
                                style: const TextStyle(
                                  color: AppColors.greyTextColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Explore Events',
                                style: TextStyle(
                                  color: AppColors.blackTextColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Ganti Tampilan Icon menjadi Tampilan Avatar yang Dinamis
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.lightBlue.withOpacity(
                              0.4,
                            ),
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.primaryColor,
                                    size: 28,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          style: const TextStyle(
                            color: AppColors.blackTextColor,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => _runFilter(value),
                          onSubmitted: (value) {
                            _runFilter(value);
                            FocusScope.of(context).unfocus();
                          },
                          decoration: const InputDecoration(
                            icon: Icon(
                              Icons.search,
                              color: AppColors.borderDark,
                            ),
                            hintText: 'Cari acara...',
                            hintStyle: TextStyle(
                              color: AppColors.greyTextColor,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_popularEvents.isNotEmpty) ...[
                        const Text(
                          'Top Popular Events',
                          style: TextStyle(
                            color: AppColors.blackTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _popularEvents.length,
                            itemBuilder: (context, index) =>
                                _buildHorizontalCard(_popularEvents[index]),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Text(
                        'Upcoming Events',
                        style: TextStyle(
                          color: AppColors.blackTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_filteredEvents.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Acara tidak ditemukan.',
                              style: TextStyle(color: AppColors.greyTextColor),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) =>
                              _buildVerticalCard(_filteredEvents[index]),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
