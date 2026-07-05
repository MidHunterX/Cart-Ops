import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'edit_purchased_item_sheet.dart';
import 'add_item_components/input_field_box.dart' show ActiveField;
import 'common/unit_quantity_selector.dart';

class PurchasedItemTile extends StatelessWidget {
  final PurchasedItemWithDetails details;
  final int index;
  final int totalItems;

  const PurchasedItemTile({
    super.key,
    required this.details,
    required this.index,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final pItem = details.purchasedItem;
    final item = details.item;
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final weightUnit = settings.weightUnit;
    final colorScheme = Theme.of(context).colorScheme;

    final pricePerUnit = pItem.price ?? 0.0;
    final qty = pItem.quantity ?? 0.0;
    final totalPrice = (pricePerUnit - pItem.discount) * qty;
    final discountApplied = pItem.discount > 0;

    final hasQty = pItem.quantity != null;
    final hasPrice = pItem.price != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isSmallScreen = maxWidth < 360;

        // Proportional sizing guarantees it looks optimal on Watches, Phones, and Tablets
        final double qtyWidth = (maxWidth * 0.18).clamp(65.0, 85.0);
        final double totalAreaWidth = (maxWidth * 0.25).clamp(80.0, 115.0);
        final double imgSize = isSmallScreen ? 40.0 : 50.0;
        final double spacing = isSmallScreen ? 8.0 : 12.0;

        return Column(
          children: [
            InkWell(
              onLongPress: () => _showEditSheet(context),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Quantity Section
                    SizedBox(
                      width: qtyWidth,
                      child: _buildQuantitySection(
                        context,
                        pItem,
                        hasQty,
                        isSmallScreen,
                        weightUnit,
                        colorScheme,
                      ),
                    ),
                    SizedBox(width: spacing),

                    // Image Section
                    if (item.imagePath != null || settings.compactItemList == false) ...[
                      _buildImageSection(item, colorScheme, imgSize),
                      SizedBox(width: spacing),
                    ],

                    // Main Details Section (Name, Unit Price, Total Price)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildItemDetails(
                              context,
                              item,
                              pItem,
                              settings,
                              colorScheme,
                              currency,
                              weightUnit,
                              hasPrice,
                              discountApplied,
                              pricePerUnit,
                            ),
                          ),
                          SizedBox(width: spacing),

                          // Total Price
                          SizedBox(
                            width: totalAreaWidth,
                            child: _buildTotalPriceSection(
                              context,
                              pItem,
                              colorScheme,
                              currency,
                              weightUnit,
                              hasPrice,
                              hasQty,
                              discountApplied,
                              totalPrice,
                              qty,
                              isSmallScreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu Button Section
                    SizedBox(
                      width: 40, // Limits wide trailing spacing
                      child: Align(alignment: Alignment.topRight, child: _buildPopupMenu(context)),
                    ),
                  ],
                ),
              ),
            ),
            if (index < totalItems - 1) Divider(height: 1, color: colorScheme.outlineVariant),
          ],
        );
      },
    );
  }

  Widget _buildQuantitySection(
    BuildContext context,
    PurchasedItem pItem,
    bool hasQty,
    bool isSmallScreen,
    String weightUnit,
    ColorScheme colorScheme,
  ) {
    if (hasQty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              pItem.isWeight
                  ? pItem.quantity!.toWeightString(weightUnit)
                  : pItem.quantity!.toWeightString(''),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            pItem.isWeight ? 'Weight' : 'Units',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    if (pItem.isWeight) {
      return Column(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
            ),
            onPressed: () => _showEditSheet(context, initialField: ActiveField.quantity),
            label: Text(weightUnit, style: const TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: UnitQuantitySelector(
            quantity: '0',
            onIncrement: () {
              context.read<PurchasedItemsRepository>().updatePurchasedItem(
                id: pItem.id,
                price: pItem.price,
                qty: 1,
                discount: pItem.discount,
                isWeight: pItem.isWeight,
              );
            },
            onDecrement: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(Item item, ColorScheme colorScheme, double imgSize) {
    return Container(
      width: imgSize,
      height: imgSize,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: item.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(item.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
              ),
            )
          : Icon(
              Icons.shopping_bag_outlined,
              color: colorScheme.onSurfaceVariant,
              size: imgSize * 0.6,
            ),
    );
  }

  Widget _buildItemDetails(
    BuildContext context,
    Item item,
    PurchasedItem pItem,
    SettingsProvider settings,
    ColorScheme colorScheme,
    String currency,
    String weightUnit,
    bool hasPrice,
    bool discountApplied,
    double pricePerUnit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.name != '' || settings.compactItemList == false) ...[
          Text(
            item.name == '' && settings.compactItemList == false ? '--' : item.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        _buildPriceInfo(
          context,
          item,
          pItem,
          settings,
          colorScheme,
          currency,
          weightUnit,
          hasPrice,
          discountApplied,
          pricePerUnit,
        ),
      ],
    );
  }

  Widget _buildPriceInfo(
    BuildContext context,
    Item item,
    PurchasedItem pItem,
    SettingsProvider settings,
    ColorScheme colorScheme,
    String currency,
    String weightUnit,
    bool hasPrice,
    bool discountApplied,
    double pricePerUnit,
  ) {
    if (!hasPrice) {
      return Text(
        'Price not set',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
      );
    }

    if (discountApplied) {
      return Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$currency${pricePerUnit.toPriceString()}',
            style: settings.compactItemList == false || item.name != ''
                ? Theme.of(context).textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.onSurfaceVariant,
                  )
                : Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
          Text(
            '$currency${(pricePerUnit - pItem.discount).toPriceString()}'
            '${pItem.isWeight ? ' /$weightUnit' : ''}',
            style: settings.compactItemList == false || item.name != ''
                ? Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  )
                : Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
          ),
        ],
      );
    }

    return Text(
      '$currency${pricePerUnit.toPriceString()}'
      '${pItem.isWeight ? ' /$weightUnit' : ''}',
      style: item.name == '' && settings.compactItemList == true
          ? Theme.of(context).textTheme.titleMedium
          : Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _buildTotalPriceSection(
    BuildContext context,
    PurchasedItem pItem,
    ColorScheme colorScheme,
    String currency,
    String weightUnit,
    bool hasPrice,
    bool hasQty,
    bool discountApplied,
    double totalPrice,
    double qty,
    bool isSmallScreen,
  ) {
    if (!hasPrice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
            ),
            onPressed: () => _showEditSheet(context, initialField: ActiveField.price),
            label: Text(
              pItem.isWeight ? '$currency/$weightUnit' : currency,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

    if (!hasQty) return const SizedBox.shrink();

    if (discountApplied) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currency${totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '-$currency${(pItem.discount * qty).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$currency${totalPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditSheet(context);
            break;
          case 'edit_quantity':
            _showEditSheet(context, initialField: ActiveField.quantity);
            break;
          case 'edit_price':
            _showEditSheet(context, initialField: ActiveField.price);
            break;
          case 'edit_discount':
            _showEditSheet(context, openDiscount: true);
            break;
          case 'delete':
            _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Edit All')]),
        ),
        const PopupMenuItem(
          value: 'edit_quantity',
          child: Row(children: [Icon(Icons.numbers), SizedBox(width: 8), Text('Edit Quantity')]),
        ),
        const PopupMenuItem(
          value: 'edit_price',
          child: Row(children: [Icon(Icons.attach_money), SizedBox(width: 8), Text('Edit Price')]),
        ),
        const PopupMenuItem(
          value: 'edit_discount',
          child: Row(
            children: [Icon(Icons.local_offer_outlined), SizedBox(width: 8), Text('Edit Discount')],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditSheet(
    BuildContext context, {
    ActiveField initialField = ActiveField.price,
    bool openDiscount = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditPurchasedItemSheet(
        purchasedItem: details.purchasedItem,
        item: details.item,
        initialField: initialField,
        openDiscountDialog: openDiscount,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    DeleteConfirmationDialog.show(
      context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "${details.item.name}"?',
      onDelete: () {
        context.read<PurchasedItemsRepository>().deletePurchasedItem(details.purchasedItem.id);
      },
    );
  }
}
