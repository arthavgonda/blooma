# Blooma Architecture

The project is organized around a lightweight Clean Architecture/MVVM-friendly structure while preserving the existing UIKit screens and flows.

## Layers

- `Application`: app lifecycle, scene setup, and root tab coordination.
- `Features`: user-facing UIKit screens, cells, reusable views, and feature-specific presentation code.
- `Domain`: app models and domain-facing value types grouped by product area.
- `Data`: controllers, services, health/permission integration, and bundled JSON resources.
- `Core`: shared design system, extensions, and cross-cutting utilities.
- `Assets.xcassets`, `Base.lproj`, and `Lottie`: visual resources kept in their native iOS locations.

## Refactor Rules

- Keep UI classes in `Features`.
- Keep pure models in `Domain`.
- Put shared services, controllers, persistence, permissions, and integrations in `Data`.
- Put styling primitives, view helpers, and tiny shared utilities in `Core`.
- Prefer adding focused model/service files over growing large mixed-purpose files.
- Preserve resource lookups through `Bundle.bloomaResourceURL(named:fileExtension:)` when loading bundled files from code.
