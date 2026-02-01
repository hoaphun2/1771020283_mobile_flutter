import 'package:flutter/material.dart';

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
