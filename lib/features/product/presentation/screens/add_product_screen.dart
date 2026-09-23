import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../promo/presentation/providers/promos_provider.dart';
import '../../domain/requests/create_product_request.dart';
import '../providers/add_product_form.dart';
import '../providers/products_providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _actualPriceController;
  late final TextEditingController _discountPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _sizeController;
  late final TextEditingController _colorNameController;
  late final TextEditingController _overOrderDiscountController;
  late final TextEditingController _freeReturnDaysController;

  // HTML Editor Controller with proper configuration
  late final HtmlEditorController _htmlController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController();
    _actualPriceController = TextEditingController();
    _discountPriceController = TextEditingController();
    _stockController = TextEditingController();
    _sizeController = TextEditingController();
    _colorNameController = TextEditingController();
    _overOrderDiscountController = TextEditingController();
    _freeReturnDaysController = TextEditingController();

    // Initialize HTML Editor Controller
    _htmlController = HtmlEditorController();

    // Listeners are added to controllers below

    // Add listeners to controllers
    _titleController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateTitle(_titleController.text);
    });
    _actualPriceController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateActualPrice(_actualPriceController.text);
    });
    _discountPriceController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateDiscountPrice(_discountPriceController.text);
    });
    _stockController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateStock(_stockController.text);
    });
    _sizeController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateCustomSize(_sizeController.text);
    });
    _colorNameController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateCustomColorName(_colorNameController.text);
    });
    _overOrderDiscountController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateOverOrderDiscount(_overOrderDiscountController.text);
    });
    _freeReturnDaysController.addListener(() {
      ref
          .read(addProductFormProvider.notifier)
          .updateFreeReturnDays(_freeReturnDaysController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _actualPriceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _sizeController.dispose();
    _colorNameController.dispose();
    _overOrderDiscountController.dispose();
    _freeReturnDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final formData = ref.read(addProductFormProvider);

    if (formData.selectedImages.length >= AddProductFormNotifier.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum ${AddProductFormNotifier.maxImages} images allowed',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newImages = <ProductImage>[];
        for (var file in result.files) {
          if (file.bytes != null &&
              (formData.selectedImages.length + newImages.length) <
                  AddProductFormNotifier.maxImages) {
            newImages.add(ProductImage(bytes: file.bytes!, name: file.name));
          }
        }
        ref.read(addProductFormProvider.notifier).addImages(newImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCustomSize() {
    ref.read(addProductFormProvider.notifier).addCustomSize();
  }

  Future<void> _addCustomColor() async {
    Color selectedColor = Colors.red;
    _colorNameController.clear(); // Clear before adding

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Custom Color',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _colorNameController,
                decoration: InputDecoration(
                  labelText: 'Color Name',
                  hintText: 'e.g., Sky Blue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => selectedColor = color,
                pickerAreaHeightPercent: 0.8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _colorNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a color name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              ref
                  .read(addProductFormProvider.notifier)
                  .addCustomColor(name, selectedColor);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
            ),
            child: const Text(
              'Add Color',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCustomColor(int index) async {
    final formData = ref.read(addProductFormProvider);
    if (index < 0 || index >= formData.selectedColors.length) return;

    final currentColor = formData.selectedColors[index];
    _colorNameController.text = currentColor.name;

    Color selectedColor = currentColor.color;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Color "${currentColor.name}"',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _colorNameController,
                decoration: InputDecoration(
                  labelText: 'Color Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => selectedColor = color,
                pickerAreaHeightPercent: 0.8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _colorNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a color name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              ref
                  .read(addProductFormProvider.notifier)
                  .updateColor(index, name, selectedColor);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
            ),
            child: const Text(
              'Update Color',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    DPrint.log("Submit Inform");
    if (!_formKey.currentState!.validate()) return;

    final formData = ref.read(addProductFormProvider);
    DPrint.log("Submit Inform 2 $formData");

    if (formData.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get HTML content from editor
    // final description = await _htmlController.getText();
    // final description = await _openHtmlEditorAndGetDescription();
    // DPrint.log("Submit Inform 3 $description");

    final facilities = <String, dynamic>{};
    if (formData.overOrderDiscount.isNotEmpty) {
      facilities['overOrderDiscount'] = double.tryParse(
        formData.overOrderDiscount,
      );
    }
    if (formData.freeReturnDays.isNotEmpty) {
      facilities['freeReturnDays'] = int.tryParse(formData.freeReturnDays);
    }

    final request = CreateProductRequest(
      title: formData.title.trim(),
      description: formData.description,
      actualPrice: double.parse(formData.actualPrice),
      discountPrice: formData.discountPrice.isNotEmpty
          ? double.parse(formData.discountPrice)
          : null,
      stock: int.parse(formData.stock),
      categoryId: formData.selectedCategoryId!,
      promoId: formData.selectedPromoId,
      sizes: formData.selectedSizes,
      colors: formData.selectedColors.map((c) => c.name).toList(),
      colorCodes: formData.selectedColors
          .map((c) => c.color.value.toRadixString(16))
          .toList(),
      images: formData.selectedImages
          .map((img) => ProductImageData(bytes: img.bytes, name: img.name))
          .toList(),
      isActive: formData.isActive,
      facilities: facilities.isNotEmpty ? facilities : null,
    );

    DPrint.log(request.actualPrice);

    final newProduct = await ref
        .read(productsProvider.notifier)
        .createProduct(request);

    if (newProduct != null && mounted) {
      // Notifications are no longer sent automatically on product creation.
      // Admins must trigger a notification manually per product (see
      // product_list_screen.dart / edit_product_screen.dart "Notify" button).

      ref.read(addProductFormProvider.notifier).reset();
      context.go(RouteEndpoint.products);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully!'),
          backgroundColor: AppColors.primaryLaurel,
        ),
      );
    } else if (mounted) {
      final errorMessage = ref.read(productsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to create product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProductFormData>(addProductFormProvider, (previous, next) {
      if (previous?.title != next.title &&
          _titleController.text != next.title) {
        _titleController.text = next.title;
      }
      if (previous?.actualPrice != next.actualPrice &&
          _actualPriceController.text != next.actualPrice) {
        _actualPriceController.text = next.actualPrice;
      }
      if (previous?.discountPrice != next.discountPrice &&
          _discountPriceController.text != next.discountPrice) {
        _discountPriceController.text = next.discountPrice;
      }
      if (previous?.stock != next.stock &&
          _stockController.text != next.stock) {
        _stockController.text = next.stock;
      }
      if (previous?.customSize != next.customSize &&
          _sizeController.text != next.customSize) {
        _sizeController.text = next.customSize;
      }
      if (previous?.customColorName != next.customColorName &&
          _colorNameController.text != next.customColorName) {
        _colorNameController.text = next.customColorName;
      }
      if (previous?.overOrderDiscount != next.overOrderDiscount &&
          _overOrderDiscountController.text != next.overOrderDiscount) {
        _overOrderDiscountController.text = next.overOrderDiscount;
      }
      if (previous?.freeReturnDays != next.freeReturnDays &&
          _freeReturnDaysController.text != next.freeReturnDays) {
        _freeReturnDaysController.text = next.freeReturnDays;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1200;

            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildLeftColumn()),
                  const SizedBox(width: 32),
                  Expanded(child: _buildRightColumn()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildLeftColumn(),
                  const SizedBox(height: 32),
                  _buildRightColumn(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductTitleSection(),
        const SizedBox(height: 24),
        _buildPricingSection(),
        const SizedBox(height: 24),
        _buildCategoryPromoSection(),
        const SizedBox(height: 24),
        _buildRichTextDescriptionSection(),
        const SizedBox(height: 24),
        _buildFacilitiesSection(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVisibilitySection(),
        const SizedBox(height: 24),
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildSizeSection(),
        const SizedBox(height: 24),
        _buildColorSection(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    final formData = ref.watch(addProductFormProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Visibility',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textAppBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the product as active or private (hidden from the app).',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryHintColor,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              formData.isActive ? 'Active / Published' : 'Private / Hidden',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: formData.isActive ? Colors.green : Colors.orange,
              ),
            ),
            value: formData.isActive,
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.5),
            inactiveThumbColor: Colors.orange,
            inactiveTrackColor: Colors.orange.withOpacity(0.5),
            onChanged: (value) {
              ref.read(addProductFormProvider.notifier).updateIsActive(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add product title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          style: TextStyle(),
          decoration: InputDecoration(
            hintText: 'Add your title...',
            hintStyle: TextStyle(color: AppColors.textSecondaryHintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryLaurel,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a product title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            children: [
              _buildPriceField('Actual Price', _actualPriceController, true),
              const SizedBox(height: 16),
              _buildPriceField(
                'Discount_Price',
                _discountPriceController,
                false,
              ),
              const SizedBox(height: 16),
              _buildPriceField('Stocks', _stockController, true),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildPriceField(
                'Actual Price',
                _actualPriceController,
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPriceField(
                'Discount Price',
                _discountPriceController,
                false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildPriceField('Stocks', _stockController, true)),
          ],
        );
      },
    );
  }

  Widget _buildPriceField(
    String label,
    TextEditingController controller,
    bool required,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          style: TextStyle(),
          decoration: InputDecoration(
            hintText:
                'Add product ${label.toLowerCase().replaceAll('_', ' ')}...',
            hintStyle: TextStyle(color: AppColors.textSecondaryHintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryLaurel,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: TextInputType.number,
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter $label';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCategoryPromoSection() {
    final categoriesState = ref.watch(categoriesProvider);
    final promosState = ref.watch(promosProvider);
    final formData = ref.watch(addProductFormProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            children: [
              _buildCategoryDropdown(categoriesState, formData),
              const SizedBox(height: 16),
              _buildPromoDropdown(promosState, formData),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildCategoryDropdown(categoriesState, formData)),
            const SizedBox(width: 16),
            Expanded(child: _buildPromoDropdown(promosState, formData)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown(
    CategoriesState categoriesState,
    ProductFormData formData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),
        if (categoriesState.isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLaurel,
                ),
              ),
            ),
          )
        else if (categoriesState.categories.isEmpty)
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No categories available',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: formData.selectedCategoryId,
            style: TextStyle(color: AppColors.textAppBlack),
            decoration: InputDecoration(
              hintText: 'Select a categories',
              hintStyle: TextStyle(color: AppColors.textSecondaryHintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryLaurel,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: categoriesState.categories.map<DropdownMenuItem<String>>((
              category,
            ) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(category.name, style: TextStyle()),
                ),
              );
            }).toList(),
            onChanged: (value) {
              ref
                  .read(addProductFormProvider.notifier)
                  .updateSelectedCategory(value);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildPromoDropdown(
    PromosState promosState,
    ProductFormData formData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select product Promo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),
        if (promosState.isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLaurel,
                ),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: formData.selectedPromoId,
            style: TextStyle(color: AppColors.textAppBlack),
            decoration: InputDecoration(
              hintText: promosState.promos.isEmpty
                  ? 'No selectable promos available'
                  : 'Select a promo',
              hintStyle: TextStyle(
                color: promosState.promos.isEmpty
                    ? Colors.orange
                    : AppColors.textSecondaryHintColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: promosState.promos.isEmpty
                      ? Colors.orange
                      : AppColors.borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: promosState.promos.isEmpty
                      ? Colors.orange
                      : AppColors.borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryLaurel,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No promo', style: TextStyle()),
              ),
              ...promosState.promos.map<DropdownMenuItem<String>>((promo) {
                return DropdownMenuItem<String>(
                  value: promo.id,
                  child: Text(
                    '${promo.title} (${promo.code})',
                    style: TextStyle(),
                  ),
                );
              }),
            ],
            onChanged: (value) {
              ref
                  .read(addProductFormProvider.notifier)
                  .updateSelectedPromo(value);
            },
          ),
      ],
    );
  }

  // Future<void> _setCursorToEnd() async {
  //   await _htmlController.evaluateJavascriptWeb('''
  //   const editor = document.querySelector('.note-editable');
  //   const range = document.createRange();
  //   const sel = window.getSelection();
  //   range.selectNodeContents(editor);
  //   range.collapse(false);
  //   sel.removeAllRanges();
  //   sel.addRange(range);
  //   editor.focus();
  // ''');
  // }

  Widget _buildRichTextDescriptionSection() {
    return Consumer(
      builder: (context, ref, child) {
        final formData = ref.watch(addProductFormProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textAppBlack,
              ),
            ),
            const SizedBox(height: 12),

            // Description Preview Box
            GestureDetector(
              onTap: _openHtmlEditorDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                constraints: const BoxConstraints(minHeight: 120),
                child: formData.description.trim().isEmpty
                    ? Text(
                        'Tap to add product description...',
                        style: TextStyle(
                          color: AppColors.textSecondaryHintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Html(
                          data: formData.description,
                          style: {
                            "body": Style(
                              fontFamily: TextStyle().fontFamily,
                              fontSize: FontSize(14),
                              color: AppColors.textAppBlack,
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                          },
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Edit Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _openHtmlEditorDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: Text('Edit Description', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLaurel,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openHtmlEditorDialog() async {
    final currentText = ref.read(addProductFormProvider).description;

    // Clear previous content
    _htmlController.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryLaurel,
            foregroundColor: Colors.white,
            title: Text(
              'Edit Product Description',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    final text = await _htmlController.getText();
                    String cleanText = text.trim();

                    // Remove empty paragraph tags
                    if (cleanText == '<p><br></p>' ||
                        cleanText == '<p></p>' ||
                        cleanText.isEmpty) {
                      cleanText = '';
                    }

                    if (mounted) {
                      ref
                          .read(addProductFormProvider.notifier)
                          .updateDescription(cleanText);
                    }
                  } catch (e) {
                    // Fallback: keep current description
                    debugPrint('getText failed: $e');
                  } finally {
                    Navigator.of(dialogContext).pop();
                    _htmlController.clear();
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HtmlEditor(
                    controller: _htmlController,
                    callbacks: Callbacks(
                      onChangeContent: (data) {
                        DPrint.log("Http Data : $data");
                      },
                    ),
                    htmlEditorOptions: HtmlEditorOptions(
                      hint: "Type your product description here...",
                      shouldEnsureVisible: true,
                      initialText: "<p></p>", // Start clean
                      autoAdjustHeight: false,
                    ),
                    htmlToolbarOptions: HtmlToolbarOptions(
                      toolbarPosition: ToolbarPosition.aboveEditor,
                      toolbarType: ToolbarType.nativeScrollable,
                      defaultToolbarButtons: [
                        StyleButtons(),
                        FontSettingButtons(fontName: false),
                        FontButtons(
                          bold: true,
                          italic: true,
                          underline: true,
                          clearAll: true,
                        ),
                        ColorButtons(foregroundColor: true),
                        ListButtons(ul: true, ol: true),
                        ParagraphButtons(),
                        InsertButtons(link: true, picture: false),
                        OtherButtons(
                          fullscreen: false,
                          codeview: true,
                          undo: true,
                          redo: true,
                        ),
                      ],
                      buttonColor: AppColors.primaryLaurel,
                      buttonSelectedColor: AppColors.primaryLaurel.withOpacity(
                        0.8,
                      ),
                    ),
                    otherOptions: const OtherOptions(height: 600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // AFTER dialog opens, set the text via JS (works on Web)
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          _htmlController.setText(
            currentText.isEmpty ? "<p></p>" : currentText,
          );
        } catch (e) {
          debugPrint("setText failed (normal on mobile): $e");
        }
      });
    }
  }

  Widget _buildFacilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Facilities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: AppColors.primaryLaurel),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _overOrderDiscountController,
                      style: TextStyle(),
                      decoration: InputDecoration(
                        hintText: 'Add over order discount price...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondaryHintColor,
                        ),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderColor),
              Row(
                children: [
                  const Icon(Icons.refresh, color: AppColors.primaryLaurel),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _freeReturnDaysController,
                      style: TextStyle(),
                      decoration: InputDecoration(
                        hintText: 'Add free return days...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondaryHintColor,
                        ),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final formData = ref.watch(addProductFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Product Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),

        // Main Upload Area
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderColor,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: formData.selectedImages.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      formData.selectedImages.first.bytes,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.primaryLaurel,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click to upload images',
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Support: JPG, PNG, GIF (Max 5MB each)',
                          style: TextStyle(
                            color: AppColors.textSecondaryHintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Thumbnail Grid (5 additional images)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            final imageIndex = index + 1; // Skip first image (main)
            final hasImage = imageIndex < formData.selectedImages.length;

            return GestureDetector(
              onTap: hasImage ? null : _pickImages,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasImage
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              formData.selectedImages[imageIndex].bytes,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(addProductFormProvider.notifier)
                                  .removeImage(imageIndex),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primaryLaurel,
                          size: 24,
                        ),
                      ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        Text(
          '${formData.selectedImages.length}/${AddProductFormNotifier.maxImages} images selected',
          style: TextStyle(color: AppColors.textSecondaryColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSizeSection() {
    final formData = ref.watch(addProductFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Product Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textAppBlack,
          ),
        ),
        const SizedBox(height: 12),

        // Custom Size Input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sizeController,
                style: TextStyle(),
                decoration: InputDecoration(
                  hintText: 'Enter product size...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryHintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLaurel,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onFieldSubmitted: (_) => _addCustomSize(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addCustomSize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLaurel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text('Set', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Default Sizes
        Text(
          'Default Sizes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AddProductFormNotifier.defaultSizes.map((size) {
            final isSelected = formData.selectedSizes.contains(size);
            return GestureDetector(
              onTap: () => ref
                  .read(addProductFormProvider.notifier)
                  .toggleDefaultSize(size),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLaurel
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLaurel
                        : AppColors.borderColor,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textAppBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Selected Sizes
        if (formData.selectedSizes.isNotEmpty) ...[
          Text(
            'Selected Sizes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formData.selectedSizes.map((size) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLaurel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryLaurel),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      size,
                      style: TextStyle(
                        color: AppColors.primaryLaurel,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => ref
                          .read(addProductFormProvider.notifier)
                          .removeSize(size),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primaryLaurel,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildColorSection() {
    final formData = ref.watch(addProductFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default Colors
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AddProductFormNotifier.defaultColors.take(3).map((color) {
            final isSelected = formData.selectedColors.any(
              (c) => c.name == color.name,
            );
            return GestureDetector(
              onTap: () => ref
                  .read(addProductFormProvider.notifier)
                  .toggleDefaultColor(color),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      color.name,
                      style: TextStyle(
                        color:
                            color.color == Colors.white ||
                                color.color == Colors.yellow
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => ref
                            .read(addProductFormProvider.notifier)
                            .toggleDefaultColor(color),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color:
                              color.color == Colors.white ||
                                  color.color == Colors.yellow
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Custom Color Input
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addCustomColor,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text(
              'Add Custom Color',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Selected Colors
        if (formData.selectedColors.isNotEmpty) ...[
          Text(
            'Selected Colors',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: formData.selectedColors.asMap().entries.map((entry) {
              final index = entry.key;
              final productColor = entry.value;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: productColor.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      productColor.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textAppBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _editCustomColor(index),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppColors.primaryLaurel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref
                          .read(addProductFormProvider.notifier)
                          .removeColor(index),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final productsState = ref.watch(productsProvider);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: productsState.isCreating
                ? null
                : () {
                    ref.read(addProductFormProvider.notifier).reset();
                    context.go(RouteEndpoint.products);
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: productsState.isCreating ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: productsState.isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
