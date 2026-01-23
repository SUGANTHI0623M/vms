import 'package:flutter/material.dart';
import '../../core/models/vendor.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_common_widgets.dart';

class VendorDetailView extends StatelessWidget {
  final Vendor vendor;

  const VendorDetailView({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CommonAppBar(
          title: vendor.companyName ?? 'Vendor Details',
          verificationStatus: vendor.verificationStatus,
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // Header with Background
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: 70,
                  child: Hero(
                    tag: 'vendor-logo-${vendor.id}',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: vendor.logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(vendor.logoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: vendor.logoUrl == null
                          ? Center(
                              child: Text(
                                (vendor.companyName ?? "?")[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Text(
              vendor.companyName ?? 'Unnamed Company',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
            if (vendor.description != null && vendor.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 40, right: 40),
                child: Text(
                  vendor.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              vendor.vendorUid ?? 'ID: Pending',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Switching Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TabBar(
                isScrollable: true,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Company'),
                  Tab(text: 'Contact'),
                  Tab(text: 'Personal'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent([
                    _buildInfoRow(
                      Icons.description,
                      'Description',
                      vendor.description,
                    ),
                    _buildInfoRow(Icons.receipt_long, 'GSTIN', vendor.gstin),
                    _buildInfoRow(Icons.language, 'Website', vendor.website),
                    _buildInfoRow(
                      Icons.location_on,
                      'Office Address',
                      vendor.officeAddress,
                    ),
                  ]),
                  _buildTabContent([
                    _buildInfoRow(
                      Icons.person,
                      'Contact Person',
                      vendor.fullName,
                    ),
                    _buildInfoRow(Icons.email, 'Email Address', vendor.email),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone Number',
                      vendor.phoneNumber,
                    ),
                  ]),
                  _buildTabContent([
                    _buildInfoRow(Icons.cake, 'Date of Birth', vendor.dob),
                    _buildInfoRow(Icons.wc, 'Gender', vendor.gender),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not Provided',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4F5D75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
