import '../../core/i18n/app_text.dart';
import 'models.dart';

/// "3 Bed", "2 Bath", "95 m²": the facts a card lists under a home, leaving
/// out any the listing does not have.
List<String> propertyFacts(AppText text, PropertySummary property, {String areaUnit = 'm²'}) => [
      if (property.bedrooms != null) text.factBeds(property.bedrooms!),
      if (property.bathrooms != null) text.factBaths(property.bathrooms!),
      if (property.sizeSqm != null) '${property.sizeSqm!.round()} $areaUnit',
    ];
