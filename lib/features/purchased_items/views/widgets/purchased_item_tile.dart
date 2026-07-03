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
    final colorScheme = Theme.of(context).colorScheme;

    final pricePerUnit = pItem.price ?? 0.0;
    final qty = pItem.quantity ?? 0.0;
    final totalPrice = (pricePerUnit - pItem.discount) * qty;
    final discountApplied = pItem.discount > 0;

    final hasQty = pItem.quantity != null;
    final hasPrice = pItem.price != null;

    return Column(
      children: [
        InkWell(
          onLongPress: () => _showEditSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Quantity Section
                    SizedBox(
                      width: 50,
                      child: hasQty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    pItem.isWeight
                                        ? pItem.quantity!.toWeightString('kg')
                                        : pItem.quantity!.toWeightString(''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    pItem.isWeight ? 'Weight' : 'Units',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Icon(Icons.inventory_2_outlined, color: colorScheme.error),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Image Section
                    Container(
                      width: 50,
                      height: 50,
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
                          : Icon(Icons.shopping_bag_outlined, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),

                    // Name Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasPrice)
                            if (discountApplied)
                              Row(
                                children: [
                                  Text(
                                    '$currency${pricePerUnit.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$currency${(pricePerUnit - pItem.discount).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                '$currency${pricePerUnit.toStringAsFixed(2)} ${pItem.isWeight ? '/kg' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                          else
                            Text(
                              'Price not set',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Price Section
                    SizedBox(
                      width: 100,
                      child: hasPrice && hasQty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (discountApplied) ...[
                                  Text(
                                    '$currency${totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '-$currency${(pItem.discount * qty).toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                                  ),
                                ] else
                                  Text(
                                    '$currency${totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TBD',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 8),

                    // Menu Section
                    PopupMenuButton<String>(
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
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit All'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_quantity',
                          child: Row(
                            children: [
                              Icon(Icons.numbers),
                              SizedBox(width: 8),
                              Text('Edit Quantity'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_price',
                          child: Row(
                            children: [
                              Icon(Icons.attach_money),
                              SizedBox(width: 8),
                              Text('Edit Price'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_discount',
                          child: Row(
                            children: [
                              Icon(Icons.local_offer_outlined),
                              SizedBox(width: 8),
                              Text('Edit Discount'),
                            ],
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
                    ),
                  ],
                ),

                // MISSING FIELDS ACTIONS
                if (!hasQty || !hasPrice)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, left: 62.0, right: 40.0),
                    child: Row(
                      children: [
                        if (!hasQty)
                          Expanded(
                            child: pItem.isWeight
                                ? OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () =>
                                        _showEditSheet(context, initialField: ActiveField.quantity),
                                    icon: const Icon(Icons.scale, size: 16),
                                    label: const Text('Add Weight', style: TextStyle(fontSize: 12)),
                                  )
                                : SizedBox(
                                    height: 40,
                                    child: UnitQuantitySelector(
                                      quantity: '0',
                                      onIncrement: () {
                                        context
                                            .read<PurchasedItemsRepository>()
                                            .updatePurchasedItem(
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
                          ),
                        if (!hasQty && !hasPrice) const SizedBox(width: 8),
                        if (!hasPrice)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () =>
                                  _showEditSheet(context, initialField: ActiveField.price),
                              icon: const Icon(Icons.attach_money, size: 16),
                              label: const Text('Set Price', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (index < totalItems - 1) Divider(height: 1, color: colorScheme.outlineVariant),
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
