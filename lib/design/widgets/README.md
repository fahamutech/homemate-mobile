# Shared widgets ↔ Figma components

Figma file `joLKZpKfnOx26AQUUeVPEC`, page **02 Components** (node `2-3`).
Every screen (customer, broker, landlord) is built from these. Before adding a
widget, check this table. If one is close, extend it or add a variant.

## Mapping

| Figma component | Dart widget | File | How it relates to what was there |
|---|---|---|---|
| `Button` (Primary, Outline, Neutral, Soft, Ghost, Danger, Danger outline × Large 52 / Medium 44 / Small 40; icon; icon-only) | `HmButton` (`HmButtonStyle`, `HmButtonSize`, `HmButtonColours.of`) | `hm_button.dart` | New. The theme's `ElevatedButton` / `OutlinedButton` still draw the older customer buttons. |
| `Badge` (Success, Warning, Error, Info, Neutral, Primary; icon) | `HmBadge` (`HmBadgeTone`, `badgeToneForStatus`) | `hm_badge.dart` | Figma's version of `hm_status_chip`. `HmStatusChip` keeps its look on customer screens; partner screens use `HmBadge`. |
| `HM/Navigation/TopBar` | `HmTopBar` | `hm_top_bar.dart` | New. |
| `HM/Navigation/BottomNavBar`, `HM/Navigation/PartnerNavBar` (Role=Broker / Landlord) | `HmBottomNav` + `HmNavTab`; tab sets `customerTabs` / `brokerTabs` / `landlordTabs` | `hm_bottom_nav.dart`, `lib/routing/nav_tabs.dart` | Replaces the customer shell's hand-built `NavigationBar`; the partner shells (T07) use the same widget. |
| `HM/Form/TextField` (Default / Focused / Error × Single / Multi; optional tag, leading icon, prefix, trailing icon, hint) | `HmTextField` | `hm_text_field.dart` | New. Focus colours come from the theme's `inputDecorationTheme`. |
| `HM/Form/StepProgress` (Steps 3 / 6) | `HmStepProgress` | `hm_step_progress.dart` | Figma's version of `HmStepHeader` (hm_choice.dart). That one stays on customer onboarding. |
| `HM/Form/Segmented` (2 / 3 options) | `HmSegmented<T>` | `hm_segmented.dart` | Variant of `HmSegmentedPills` (hm_choice.dart): grey track with the choice on white. The pills keep the filled-teal look in the customer filter. |
| `HM/Form/Chip` (selected / not; check; count) | `HmChoicePill(dense: true, showCheck:, count:)` | `hm_choice.dart` | Existing pill, extended with `showCheck` and `count`. |
| `HM/Form/RadioCard` | `HmRadioCard` | `hm_radio_card.dart` | New. The single-choice counterpart of `hm_choice`. |
| `HM/Feedback/Note` (Neutral, Brand, Success, Warning, Info) | `HmNote` (`HmNoteTone`) | `hm_note.dart` | Figma's version of `HmNotice` (hm_section.dart), which stays on customer screens. |
| `HM/Data/KeyValue` (Default, Strong, Total, Brand) | `HmKeyValue` (`HmKeyValueEmphasis`) | `hm_key_value.dart` | Figma's version of `HmDetailRow` (hm_section.dart), which stays on customer screens. |
| `HM/List/ListTile` (plain / boxed icon) | `HmListTile` | `hm_list_tile.dart` | New. |
| `HM/Partner/AttentionRow` (Orange, Red, Blue, Green) | `HmAttentionRow` (`HmAttentionTone`) | `hm_attention_row.dart` | New. |
| `HM/Partner/RoleHeader` | `HmRoleHeader` | `hm_role_header.dart` | New. The role chip opens the switcher (ROL-002). |
| `HM/Partner/ListingCard` | `HmListingCard` | `hm_listing_card.dart` | New. Customer cards stay in `features/shared/property_card.dart`. |
| `HM/Partner/StatCard` | `HmStatCard` | `hm_stat_card.dart` | New. |
| `HM/Partner/DocumentCard` | `HmDocumentCard` | `hm_document_card.dart` | New. It is built from `HmButton` and `HmIconBox`. |
| `HM/Partner/MoneyRow` | `HmMoneyRow` | `hm_money_row.dart` | New. Amounts are formatted with `HmMoney` (hm_money.dart). |
| `HM/Layout/SectionHeader` | `HmSectionHeader` | `hm_section.dart` | Existing, reused as is. |
| `HM/Workflow/TimelineStep` (Done, Current, Upcoming; plus Blocked) | `HmTimelineStep` (`HmStepState.fromServer`) | `hm_timeline_step.dart` | Figma's single step. `HmTimeline` (hm_timeline.dart) keeps drawing the customer journey. |
| `HM/Onboarding/Slide` (Step 1–3) | `HmSlide` + `HmPageDots` | `hm_slide.dart` | Lifted out of the customer onboarding screen, which now uses it. The broker and landlord intros use it too. |

### Building blocks shared by the widgets above

| Widget | File | Used by |
|---|---|---|
| `HmIconBox` | `hm_icon_box.dart` | ListTile, AttentionRow, DocumentCard |
| `HmCardSurface` | `hm_card_surface.dart` | ListingCard, StatCard, DocumentCard |
| `HmCountBadge` | `hm_bottom_nav.dart` | tab icons |

### Widgets that were here before

`hm_scaffold`, `hm_section` (`HmSectionHeader`, `HmListRow`, `HmDetailRow`,
`HmCard`, `HmNotice`), `hm_status_chip`, `hm_timeline`, `hm_choice`,
`hm_feedback`, `hm_money`, `hm_prompt`, `hm_async`.

## Tokens

The tints the partner components use are in `lib/design/tokens.dart`:

- `brandSubtle`, `brandBorder`, `textTertiary`.
- The status pairs: `greenBg`/`greenText`, `orangeBg`/`orangeBorder`/`orangeText`,
  `blueBg`/`blueBorder`/`blueText`, `redBg`/`redText`, `amberBg`/`amberText`,
  `infoBg`/`infoText`, `successSubtle`.
- The teal-12% tint is `brandPrimarySoft`.

## Catalogue

In a debug build, `/dev/widgets` shows every widget in every state. The
language button switches it between Kiswahili and English. Tests live in
`test/design/` and `test/widget_catalogue_test.dart`.
