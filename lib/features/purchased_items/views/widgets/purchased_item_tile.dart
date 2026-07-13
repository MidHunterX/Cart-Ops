import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/widgets/delete_confirmation_dialog.dart';
import 'package:shopping_assist/core/widgets/item_image_view.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import 'package:shopping_assist/core/utils/number_formatter.dart';
import 'edit_purchased_item_sheet.dart';
import 'add_item_components/input_field_box.dart' show ActiveField;

double _calcTotalPrice(double price, double discount, double quantity) {
  final priceDec = Decimal.parse(price.toString());
  final discountDec = Decimal.parse(discount.toString());
  final quantityDec = Decimal.parse(quantity.toString());

  final total = (priceDec - discountDec) * quantityDec;
  return total.toDouble();
}

double _calcTotalDiscount(double discount, double quantity) {
  final total = Decimal.parse(discount.toString()) * Decimal.parse(quantity.toString());
  return total.toDouble();
}

double _calcRateAfterDiscount(double price, double discount) {
  final total = Decimal.parse(price.toString()) - Decimal.parse(discount.toString());
  return total.toDouble();
}

class PurchasedItemTile extends StatelessWidget {
  final PurchasedItemWithDetails details;
  final int index;
  final int totalItems;

  final bool isSelected;
  final VoidCallback onMenuOpened;
  final VoidCallback onMenuClosed;

  const PurchasedItemTile({
    super.key,
    required this.details,
    required this.index,
    required this.totalItems,

    this.isSelected = false,
    required this.onMenuOpened,
    required this.onMenuClosed,
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
    final totalPrice = _calcTotalPrice(pricePerUnit, pItem.discount, qty);
    final discountApplied = pItem.discount > 0;

    final hasQty = pItem.quantity != null;
    final hasPrice = pItem.price != null;

    final tileBgColor = isSelected ? colorScheme.surfaceContainerHighest : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isSmallScreen = maxWidth < 360;

        final double qtyWidth = (maxWidth * 0.18).clamp(65.0, 85.0);
        final double totalAreaWidth = (maxWidth * 0.25).clamp(80.0, 115.0);
        final double imgSize = isSmallScreen ? 40.0 : 50.0;
        final double spacing = isSmallScreen ? 8.0 : 12.0;

        return Column(
          children: [
            Material(
              color: tileBgColor,
              child: InkWell(
                onLongPress: () => _showEditSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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

                      if (details.item.imagePath != null ||
                          details.purchasedItem.imagePath != null ||
                          settings.compactItemList == false) ...[
                        _buildImageSection(details, colorScheme, imgSize),
                        SizedBox(width: spacing),
                      ],

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

                      SizedBox(
                        width: 40,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: _buildPopupMenu(context, colorScheme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index < totalItems - 1) const Divider(height: 1),
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

    return Column(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          ),
          onPressed: () => _showEditSheet(context, initialField: ActiveField.quantity),
          label: Text(pItem.isWeight ? weightUnit : 'Qty', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildImageSection(PurchasedItemWithDetails pid, ColorScheme colorScheme, double imgSize) {
    return ItemImageView(
      imagePath: pid.item.imagePath ?? pid.purchasedItem.imagePath,
      size: imgSize,
      placeholderIconSize: imgSize * 0.6,
      heroTag: 'purchasedItemTile-${pid.purchasedItem.id}',
      enableTapToView: true,
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

    final ratePerItem = pricePerUnit.toCurrencyString(currency, preferWhole: true);
    final unit = pItem.isWeight ? '/$weightUnit' : '';

    if (discountApplied) {
      final ratePerDiscountedItem = _calcRateAfterDiscount(
        pricePerUnit,
        pItem.discount,
      ).toCurrencyString(currency, preferWhole: true);

      return Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            ratePerItem,
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
            '$ratePerDiscountedItem$unit',
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
      '$ratePerItem$unit',
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
              totalPrice.toCurrencyString(currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _calcTotalDiscount(-pItem.discount, qty).toCurrencyString(currency),
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
            totalPrice.toCurrencyString(currency),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onOpened: onMenuOpened,
      onCanceled: onMenuClosed,
      onSelected: (value) {
        onMenuClosed(); // Reset highlight on selection
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
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: colorScheme.error)),
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
      showDragHandle: true,
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
