import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/models/public_profile_model.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/cubit/owner_profile_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/presentation/cubit/owner_profile_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const Color _pageBg = Color(0xFFF5F6FA);
const Color _cardBorder = Color(0xFFF0F2F5);

String _monthYear(DateTime? d) =>
    d == null ? '' : '${_months[d.month - 1]} ${d.year}';

/// Public profile of another user (the property owner / host), fetched from
/// `GET /users/{id}`. Mirrors the web `profile/[id]` page for a guest viewer
/// (no email/phone/sidebar; Overview = language + currency only).
class OwnerProfileScreen extends StatefulWidget {
  final String userId;

  const OwnerProfileScreen({super.key, required this.userId});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.userId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.tr('ownerProfile.copied')),
        duration: const Duration(milliseconds: 1500),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.charcoal),
        title: Text(
          context.tr('ownerProfile.backToPropertyDetails'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: BlocBuilder<OwnerProfileCubit, OwnerProfileState>(
        builder: (context, state) {
          if (state is OwnerProfileLoading || state is OwnerProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.charcoal),
            );
          }
          if (state is OwnerProfileError) {
            return _ErrorView(messageKey: state.messageKey);
          }
          return _buildContent((state as OwnerProfileLoaded).profile);
        },
      ),
    );
  }

  Widget _buildContent(PublicProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(
            profile: profile,
            userId: widget.userId,
            onCopyId: _copyId,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.charcoal,
                  unselectedLabelColor: AppColors.neutral400,
                  indicatorColor: AppColors.charcoal,
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: context.tr('ownerProfile.tabOverview')),
                    Tab(text: context.tr('ownerProfile.tabProperties')),
                    Tab(text: context.tr('ownerProfile.tabReviews')),
                    Tab(text: context.tr('ownerProfile.tabTrips')),
                  ],
                ),
                AnimatedBuilder(
                  animation: _tab,
                  builder: (_, __) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: _tabBody(_tab.index, profile),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(int index, PublicProfileModel profile) {
    switch (index) {
      case 0:
        return _OverviewTab(user: profile.user);
      case 1:
        return _PropertiesTab(properties: profile.effectiveProperties);
      case 2:
        return _ReviewsTab(ratings: profile.user.hostRatings);
      case 3:
      default:
        return _TripsTab(trips: profile.user.guestBookings);
    }
  }
}

// ─── Header card ──────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final PublicProfileModel profile;
  final String userId;
  final VoidCallback onCopyId;

  const _HeaderCard({
    required this.profile,
    required this.userId,
    required this.onCopyId,
  });

  String? _roleLabel(BuildContext context, String? role) {
    switch (role) {
      case 'GUEST_AND_HOST':
        return context.tr('ownerProfile.roleGuestHost');
      case 'GUEST':
        return context.tr('ownerProfile.roleGuest');
      case 'HOST':
        return context.tr('ownerProfile.roleHost');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final photo = profile.photoUrl;
    final location = user.address?.displayLocation ?? '';
    final member = _monthYear(user.createdAt);
    final roleLabel = _roleLabel(context, user.role);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Container(
                      color: AppColors.bioYellow,
                      child: (photo != null && photo.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _initials(user.initials),
                            )
                          : _initials(user.initials),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (roleLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onCopyId,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '"$userId"',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                      if (location.isNotEmpty || member.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (location.isNotEmpty)
                              _MetaChip(
                                  icon: Icons.place_outlined, text: location),
                            if (member.isNotEmpty)
                              _MetaChip(
                                  icon: Icons.calendar_today_outlined,
                                  text: member),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          _StatsBar(profile: profile),
        ],
      ),
    );
  }

  Widget _initials(String initials) => Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.charcoal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      );
}

// ─── Stats bar (6 cells) ──────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final PublicProfileModel profile;

  const _StatsBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final u = profile.user;
    final r = profile.rating;
    final cells = <_StatData>[
      _StatData(Icons.home_outlined, '${u.properties.length}',
          context.tr('ownerProfile.statsProperties'), Colors.blue),
      _StatData(
          Icons.calendar_today_outlined,
          '${u.guestBookings.length + u.hostBookings.length}',
          context.tr('ownerProfile.statsBookings'),
          Colors.purple),
      _StatData(
          Icons.star_outline,
          r?.averageRating != null ? r!.averageRating!.toStringAsFixed(1) : 'N/A',
          context.tr('ownerProfile.statsRating'),
          Colors.amber),
      _StatData(Icons.star, '${r?.totalRatings ?? 0}',
          context.tr('ownerProfile.statsReviews'), Colors.amber),
      _StatData(
          Icons.public,
          (u.nationality?.trim().isNotEmpty == true)
              ? u.nationality!.trim()
              : '—',
          context.tr('ownerProfile.statsNationality'),
          Colors.green),
      _StatData(Icons.shield_outlined, u.kycStatus ?? '—',
          context.tr('ownerProfile.statsKyc'), Colors.orange),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: cells
          .map((c) => Container(
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white12),
                    bottom: BorderSide(color: Colors.white12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, size: 14, color: c.color),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        c.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    Text(
                      c.label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _StatData(this.icon, this.value, this.label, this.color);
}

// ─── Overview tab ─────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PublicUserModel user;

  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final lang = user.preferredLanguage == 'en'
        ? 'English'
        : (user.preferredLanguage ?? '—');
    final currency = user.preferredCurrency ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('ownerProfile.contactInformation'),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal),
        ),
        const SizedBox(height: 16),
        _InfoRow(
            icon: Icons.public,
            label: context.tr('ownerProfile.contactLanguage'),
            value: lang),
        const SizedBox(height: 12),
        _InfoRow(
            icon: Icons.schedule,
            label: context.tr('ownerProfile.contactCurrency'),
            value: currency),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.neutral400),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.5,
                color: AppColors.neutral400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

// ─── Properties tab ───────────────────────────────────────────────────────

class _PropertiesTab extends StatelessWidget {
  final List<PublicPropertyModel> properties;

  const _PropertiesTab({required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return _EmptyState(
        icon: Icons.home_outlined,
        text: context.tr('ownerProfile.noPropertiesListed'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('ownerProfile.propertiesHeading'),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal),
        ),
        const SizedBox(height: 16),
        ...properties.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: (p.id != null && p.id!.isNotEmpty)
                    ? () => Navigator.pushNamed(
                          context,
                          Routes.propertyDetails,
                          arguments: {'propertyId': p.id},
                        )
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                            fontSize: 14),
                      ),
                      if (p.description != null &&
                          p.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.neutral400),
                        ),
                      ],
                      if (p.pricePerNight != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${p.pricePerNight} ${context.tr('ownerProfile.perNight')}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Reviews tab ──────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final List<PublicHostRating> ratings;

  const _ReviewsTab({required this.ratings});

  @override
  Widget build(BuildContext context) {
    final summary = ReviewSummary.fromRatings(ratings);
    if (summary.totalReviews == 0) {
      return _EmptyState(
        icon: Icons.star_border,
        text: context.tr('ownerProfile.noReviewsYet'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 6),
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                summary.totalReviews == 1
                    ? 'ownerProfile.reviewSingular'
                    : 'ownerProfile.reviewPlural',
                args: {'n': summary.totalReviews},
              ),
              style: const TextStyle(color: AppColors.neutral400),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ratings.map((r) => _ReviewCard(rating: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PublicHostRating rating;

  const _ReviewCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final photo = rating.reviewerPhoto;
    final stars = rating.ratingValue.round().clamp(0, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.ghostWhite,
                backgroundImage: (photo != null && photo.isNotEmpty)
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: (photo == null || photo.isEmpty)
                    ? Text(
                        rating.reviewerName.isNotEmpty
                            ? rating.reviewerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.reviewerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.charcoal),
                    ),
                    if (rating.createdAt != null)
                      Text(
                        _monthYear(rating.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral400),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.neutral600, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Trips tab ────────────────────────────────────────────────────────────

class _TripsTab extends StatelessWidget {
  final List<PublicBooking> trips;

  const _TripsTab({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_today_outlined,
        text: context.tr('ownerProfile.noTripsYet'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('ownerProfile.tripsHeading'),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal),
        ),
        const SizedBox(height: 16),
        ...trips.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.propertyName ?? 'Booking',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.charcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.checkIn ?? '—'} → ${b.checkOut ?? '—'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.neutral400),
                        ),
                      ],
                    ),
                  ),
                  if (b.status != null && b.status!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b.status!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600),
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.neutral200),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral400),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String messageKey;

  const _ErrorView({required this.messageKey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 28, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(messageKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(context.tr('ownerProfile.goBack')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
