import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showCart;
  final bool showBack;
  final VoidCallback? onCartPressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showCart = false,
    this.showBack = false,
    this.onCartPressed,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation,
      centerTitle: true,
      leading: leading ?? (showBack ? _buildBackButton(context) : null),
      actions: _buildActions(context),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      onPressed: onBackPressed ?? () => context.canPop() ? context.pop() : context.go('/home'),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actionsList = <Widget>[];

    if (showCart) {
      actionsList.add(_buildCartButton(context));
    }

    if (actions != null) {
      actionsList.addAll(actions!);
    }

    return actionsList;
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.totalItems;
        
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: badges.Badge(
            badgeContent: Text(
              itemCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            showBadge: itemCount > 0,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: AppColors.error,
              padding: EdgeInsets.all(6),
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: onCartPressed ?? () {
                context.go('/cart');
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
