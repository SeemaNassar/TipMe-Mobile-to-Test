import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/models/country.dart';
import 'package:tipme_app/providersChangeNotifier/profileSetupProvider.dart';
import 'package:tipme_app/services/cacheService.dart';
import 'package:tipme_app/utils/app_font.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:intl/intl.dart'; // Add this import

import '../../../routs/app_routs.dart';
import '../../../data/services/language_service.dart';
import '../../../core/dio/client/dio_client.dart';

import '../../widgets/onboarding_layout.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/progress_next_button.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _cacheService =
      CacheService(sl<DioClient>(instanceName: 'CacheService'));

  String? _selectedNationality;
  String? _selectedCountryId;
  String? _selectedCityId;

  List<Country> _countries = [];
  List<City> _cities = [];
  List<String> _nationalities = [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final countries = await _cacheService.getCountries();
    final nationalities = await _cacheService.getNationalities();
    if (mounted) {
      setState(() {
        _countries = countries;
        _nationalities = nationalities;
      });
    }
  }

  Future<void> _loadCities(String countryId) async {
    final cities = await _cacheService.getCities(countryId);
    if (mounted) {
      setState(() {
        _cities = cities;
        _selectedCityId = null; // reset selected city when country changes
      });
    }
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _surnameController.text.isNotEmpty &&
        _dateOfBirthController.text.isNotEmpty &&
        _selectedNationality != null &&
        _selectedCountryId != null &&
        _selectedCityId != null;
  }

  void _onNext() {
    if (_isFormValid && _formKey.currentState?.validate() == true) {
      final provider =
          Provider.of<ProfileSetupProvider>(context, listen: false);

      // Parse the formatted date back to DateTime
      final birthdate = _parseFormattedDate(_dateOfBirthController.text);

      provider.update(
          firstName: _firstNameController.text.trim(),
          surName: _surnameController.text.trim(),
          birthdate: birthdate ?? DateTime.now(),
          nationality: _selectedNationality!,
          countryId: _selectedCountryId!,
          cityId: _selectedCityId!,
          bankCountryId: _selectedCountryId! // TODO:: Remove
          );

      Navigator.of(context).pushNamed(AppRoutes.documentUpload);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          // Format date as "12 Sep, 2007"
          final formattedDate = DateFormat('d MMM, yyyy').format(picked);
          _dateOfBirthController.text = formattedDate;
        });
      }
    }
  }

  // Helper function to parse formatted date back to DateTime
  DateTime? _parseFormattedDate(String formattedDate) {
    try {
      return DateFormat('d MMM, yyyy').parse(formattedDate);
    } catch (e) {
      return null;
    }
  }

  Widget _buildHeaderComponent() {
    final languageService = Provider.of<LanguageService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 400 : screenSize.width - 48,
      ),
      child: Text(
        languageService.getText('profileSetupSubtitle'),
        style:
            AppFonts.mdMedium(context, color: AppColors.white.withOpacity(0.9)),
        textAlign: TextAlign.center,
        maxLines: 3,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return OnboardingLayout(
      step: 2,
      totalSteps: 5,
      title: languageService.getText('letsMakeTippingEasy'),
      headerComponent: _buildHeaderComponent(),
      content: _buildProfileForm(languageService),
      nextButton: ProgressNextButton(
        onPressed: _isFormValid ? _onNext : null,
        isEnabled: _isFormValid,
        currentStep: 2,
        totalSteps: 5,
      ),
      topPadding: 16.0,
      bottomPadding: 48.0,
    );
  }

  Widget _buildProfileForm(LanguageService languageService) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: languageService.getText('firstName'),
                  controller: _firstNameController,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? languageService.getText('firstNameRequired')
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  hintText: languageService.getText('surname'),
                  controller: _surnameController,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? languageService.getText('surnameRequired')
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            hintText: languageService.getText('dateOfBirth'),
            controller: _dateOfBirthController,
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/icons/calendar-week.svg',
                  color: AppColors.text,
                ),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return languageService.getText('dateOfBirthRequired');
              }

              // Validate that the date format is correct
              final parsedDate = _parseFormattedDate(value!);
              if (parsedDate == null) {
                return languageService.getText('invalidDateFormat');
              }

              return null;
            },
          ),
          const SizedBox(height: 24),

          /// Nationality (string)
          CustomDropdownField(
            hintText: languageService.getText('nationality'),
            value: _selectedNationality,
            items: _nationalities
                .map((n) => DropdownMenuItem<String>(
                      value: n,
                      child: Text(n),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedNationality = value);
            },
            validator: (value) => (value == null)
                ? languageService.getText('nationalityRequired')
                : null,
          ),
          const SizedBox(height: 24),

          /// Country (id)
          CustomDropdownField(
            hintText: languageService.getText('country'),
            value: _selectedCountryId,
            items: _countries
                .map((c) => DropdownMenuItem<String>(
                      value: c.id, // store ID
                      child: Text(c.name), // display name
                    ))
                .toList(),
            onChanged: (value) {
              final country = _countries.firstWhere((c) => c.id == value,
                  orElse: () => _countries.first);
              setState(() {
                _selectedCountryId = country.id;
                _loadCities(country.id);
              });
            },
            validator: (value) => (value == null)
                ? languageService.getText('countryRequired')
                : null,
          ),
          const SizedBox(height: 24),

          /// City (id)
          CustomDropdownField(
            hintText: languageService.getText('city'),
            value: _selectedCityId,
            items: _cities
                .map((c) => DropdownMenuItem<String>(
                      value: c.id, // store ID
                      child: Text(c.name), // display name
                    ))
                .toList(),
            onChanged: (value) {
              final city = _cities.firstWhere((c) => c.name == value,
                  orElse: () => _cities.first);
              setState(() => _selectedCityId = city.id);
            },
            validator: (value) => (value == null)
                ? languageService.getText('cityRequired')
                : null,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
