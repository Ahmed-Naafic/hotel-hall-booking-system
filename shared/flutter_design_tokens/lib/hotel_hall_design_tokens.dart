/// Shared Flutter design-token / ThemeData package for the Hotel Hall
/// Booking Management System (FE-00). Ports
/// `Hotel Hall Design System/tokens/*.css` — colors, typography, spacing,
/// radii, motion, elevation — into Dart/Flutter constants and a
/// `ThemeData` builder, consumed by both `apps/customer-mobile` and
/// `apps/manager-mobile` (`folder-structure.md` §5: reusable across two or
/// more apps, so it lives in the repository-root `shared/`, not inside
/// either app).
library;

export 'src/colors.dart';
export 'src/elevation.dart';
export 'src/motion.dart';
export 'src/palette.dart';
export 'src/radii.dart';
export 'src/spacing.dart';
export 'src/theme.dart';
export 'src/typography.dart';
