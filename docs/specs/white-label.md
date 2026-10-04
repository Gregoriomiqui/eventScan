# Spec: EventScan White Label

| Campo | Valor |
|---|---|
| Autor | José Gregorio Miquilena |
| Estado | Borrador v0.2 (decisiones de §13 incorporadas) |
| Fecha | 2026-10-03 |
| Plataforma | Android (Flutter ≥ 3.38, Dart ^3.11) |
| Backend | Supabase (PostgREST) |

---

## 1. Resumen

Convertir EventScan en una app **White Label de build-time**: cada cliente/evento ("marca") se define en una carpeta `brands/<marca>/` con archivos de configuración y assets. Al compilar con `--flavor <marca>` se genera un APK independiente con su propio nombre, logo, ícono, `applicationId`, design system, idioma y esquema de datos de asistentes y staff.

El núcleo funcional se mantiene: check-in de **asistentes** y **staff**, validación por **código de inscripción o RUT**, y **descarga de listados** en PDF.

## 2. Contexto: estado actual del código

La app ya tiene una base sólida (Clean Architecture + BLoC, data sources parametrizables por tabla/columna), pero tiene acoplados a un evento específico la identidad, el diseño, los textos y el modelo de datos.

| Área | Situación actual | Archivo(s) |
|---|---|---|
| Nombre | `'Event Scan'` en `MaterialApp.title` y AppBar; `android:label="event_scan"`; `applicationId = com.example.event_scan` | `main.dart`, `check_in_mode_page.dart`, `AndroidManifest.xml`, `build.gradle.kts` |
| Logo | No existe; se usa `Icons.qr_code_2`. Ícono de launcher por defecto de Flutter | `check_in_mode_page.dart`, `mipmap-*` |
| Colores | Constantes estáticas en `AppColors` (paleta magenta). 52 referencias directas en 7 archivos | `core/theme/app_colors.dart` |
| Tipografía | Montserrat + Playfair Display vía `google_fonts` (descarga en runtime) | `core/theme/app_theme.dart` |
| Bordes/espaciado | Radios hardcodeados (10, 12, 14, 16, 18) en 17 lugares; ~32 `SizedBox`/`EdgeInsets` literales | widgets y páginas |
| Idioma | ~120 strings en español hardcodeados (UI, errores, PDF). Sin i18n | todo `lib/` |
| Modelo de datos | `Attendee` con campos fijos de un evento (`distrito`, `iglesia`, `tallerAm`, `tallerPm`, `estadoPago`). `AttendeeModel.fromJson` con alias de columnas fijos | `domain/entities/attendee.dart`, `data/models/attendee_model.dart` |
| Columna de check-in | `'CHECK_IN'` hardcodeado en el `update` | `core/network/app_supabase_client.dart` |
| Regla de negocio | Bloqueo si `ESTADO_PAGO == 'PENDIENTE'` hardcodeado en entidad y BLoC | `attendee.dart`, `check_in_bloc.dart`, `check_in_page.dart` |
| Ficha | Etiquetas y campos fijos; `showWorkshops` booleano para staff | `attendee_details_card.dart` |
| Exportación PDF | Columnas excluidas fijas (`ID_REGISTRO`, `URL_CODIGO_QR`, …) + `ID_TALLER_AM/PM` en `main.dart`; títulos fijos en español | `check_in_pdf_export_service.dart`, `main.dart` |
| Config backend | `--dart-define` para URL, anon key, tablas y columnas | `core/network/api_config.dart` |

## 3. Objetivos

1. Generar una app por marca **sin modificar código Dart**: solo agregando `brands/<marca>/` y registrando el flavor.
2. Parametrizar por archivo de configuración:
   - Design system (paleta, tipografías, escala tipográfica, radios, espaciados, bordes, elevaciones, parámetros de componentes).
   - Logo e ícono de la aplicación.
   - Nombre de la aplicación.
   - Idioma.
   - Esquema de entrada de la BD para asistentes y staff (tabla, columnas, campos a mostrar, reglas, exportación).
3. Validar la configuración en build y fallar temprano con mensajes claros.
4. Mantener o aumentar la cobertura de tests actual.

## 4. No objetivos

- Configuración remota o multi-tenant en una sola app instalada (fuera de alcance; posible fase futura).
- Soporte iOS, web o desktop.
- Editor visual de marcas o panel de administración.
- Cambiar el backend (sigue siendo Supabase) o crear nuevos módulos funcionales.
- Modo offline / cola de check-ins.

## 5. Invariantes no negociables

Estas reglas son parte del núcleo y **ninguna configuración de marca puede desactivarlas o alterarlas**.

| ID | Invariante |
|---|---|
| INV-1 | Existen exactamente dos módulos de check-in: **Asistentes** y **Staff**. La marca puede cambiar sus etiquetas, ícono y campos, no eliminarlos. |
| INV-2 | La identificación se hace por **código de inscripción** o **RUT**, ingresado manualmente o leído desde QR. |
| INV-3 | Se conserva la lógica de normalización actual de `UidValidator` (extracción desde texto de QR, limpieza de puntos/espacios, inserción del guion en RUT, mayúsculas en DV) y el fallback de búsqueda tolerante de RUT. |
| INV-3a | **Formato canónico del RUT:** cuerpo de 7 u 8 dígitos sin puntos, guion y dígito verificador (`0-9` o `K`). Ejemplo: `26905429-8`. Patrón: `^\d{7,8}-[0-9K]$`. La validación es **solo de formato**, igual que hoy; no se calcula el módulo 11. Entradas como `26.905.429-8`, `269054298` o `26905429-8` desde un QR se normalizan a `26905429-8` antes de validar y consultar. El formato del RUT no es configurable por marca. |
| INV-4 | El flujo es siempre **Validar → mostrar ficha → Confirmar**. No se puede confirmar sin validar, ni confirmar dos veces (`checkIn == true` deshabilita confirmar). |
| INV-5 | Ambos módulos ofrecen **Descargar listado PDF** (guardar en el dispositivo y abrir). |
| INV-6 | La config de marca solo puede **agregar** reglas de bloqueo a la confirmación, nunca saltarse las validaciones de INV-2 a INV-4. |

## 6. Arquitectura propuesta

### 6.1 Estructura de carpetas

```
eventScan/
├── brands/
│   ├── _schema/                    # JSON Schemas para validar configs
│   │   ├── brand.schema.json
│   │   ├── theme.schema.json
│   │   └── entities.schema.json
│   ├── default/                    # Marca actual (migración 1:1 de lo existente)
│   │   ├── brand.json              # identidad + idioma
│   │   ├── theme.json              # design system (tokens)
│   │   ├── entities.json           # esquema BD asistentes/staff
│   │   ├── assets/
│   │   │   ├── logo.svg | logo.png
│   │   │   ├── logo_on_primary.png # opcional, para fondos de color
│   │   │   └── fonts/*.ttf
│   │   ├── android/
│   │   │   ├── ic_launcher.png     # 1024x1024 fuente
│   │   │   └── ic_launcher_foreground.png  # adaptive icon (opcional)
│   │   ├── secrets.example.json    # plantilla versionada (sin valores reales)
│   │   └── secrets.json            # SUPABASE_URL / ANON_KEY, solo local (gitignored)
│   └── <otra_marca>/ …
├── lib/
│   ├── core/
│   │   ├── brand/                  # NUEVO
│   │   │   ├── brand_config.dart        # modelos inmutables
│   │   │   ├── brand_loader.dart        # carga y valida desde assets
│   │   │   └── brand_scope.dart         # InheritedWidget / provider
│   │   ├── design_system/          # reemplaza core/theme
│   │   │   ├── tokens.dart              # AppTokens (ThemeExtension)
│   │   │   ├── theme_builder.dart       # tokens → ThemeData
│   │   │   └── components/              # AppCard, AppIconBadge, AppSection, …
│   │   ├── l10n/                   # ARB + código generado
│   │   └── …
│   └── features/check_in/ …
└── tool/
    ├── validate_brand.dart         # valida JSON contra schemas
    └── new_brand.dart              # scaffold de marca nueva (opcional)
```

### 6.2 Flujo de arranque

```
main()
 ├─ appFlavor (flutter/services) → "acme"
 ├─ BrandLoader.load("brands/acme/")   → BrandConfig (brand + theme + entities)
 │    └─ si falla validación → ConfigErrorApp (lista de errores legibles)
 ├─ ApiConfig.fromEnvironment()        → secrets vía --dart-define-from-file
 ├─ Construye data sources/repos a partir de entities.attendees y entities.staff
 └─ runApp(BrandScope(config, child: EventScanApp(...)))
       ├─ theme: ThemeBuilder.build(config.theme)
       ├─ locale: config.brand.locale
       └─ title: config.brand.appName
```

### 6.3 Mecanismo de build

- **Gradle `productFlavors`** (dimensión `brand`): define `applicationId`, `resValue("string", "app_name", …)` y recursos por flavor en `android/app/src/<marca>/res/` (íconos generados). Recomendado: que `build.gradle.kts` lea `brands/*/brand.json` y genere los flavors automáticamente para que agregar una marca no requiera tocar Gradle.
- **Assets condicionados por flavor** (soportado desde Flutter 3.19):
  ```yaml
  flutter:
    assets:
      - path: brands/default/
        flavors: [default]
      - path: brands/acme/
        flavors: [acme]
  ```
  Así cada APK solo empaqueta los assets de su marca.
- **Secretos (gestión local):** `--dart-define-from-file=brands/<marca>/secrets.json`. El archivo vive solo en la máquina de quien compila, está en `.gitignore` (`brands/*/secrets.json`) y nunca se incluye en `brand.json`. Se versiona `secrets.example.json` con las claves esperadas y valores de ejemplo. Si falta `secrets.json` al compilar, el script de build se detiene con un mensaje que indica copiar la plantilla.
- **Keystores de firma (gestión local):** `android/keystores/<marca>.jks` y `android/key-<marca>.properties`, ambos gitignored. El CI no firma ni publica APKs.
- **Ícono de launcher**: `flutter_launcher_icons` con un config por flavor (`flutter_launcher_icons-<marca>.yaml`), generado a partir de `brands/<marca>/android/`.
- **Firma**: keystore por marca vía `key-<marca>.properties` (hoy release firma con debug keys).

Comando objetivo:

```bash
flutter build apk --flavor acme --dart-define-from-file=brands/acme/secrets.json
```

## 7. Esquema de configuración

### 7.1 `brand.json` — identidad e idioma

```json
{
  "$schema": "../_schema/brand.schema.json",
  "id": "acme",
  "appName": "Acme Check-in",
  "android": {
    "applicationId": "cl.acme.checkin"
  },
  "logo": {
    "primary": "assets/logo.png",
    "onPrimary": "assets/logo_on_primary.png",
    "dark": "assets/logo_dark.png",
    "showInAppBar": true,
    "showInHome": true,
    "showInPdf": true
  },
  "locale": "es-CL",
  "themeMode": "system",
  "home": {
    "title": "Control de Acceso",
    "subtitle": "Selecciona el flujo de check-in y gestiona tus listados PDF."
  }
}
```

| Campo | Requerido | Notas |
|---|---|---|
| `id` | Sí | Debe coincidir con el nombre del flavor y de la carpeta. `[a-z][a-z0-9_]*` |
| `appName` | Sí | Usado en launcher, `MaterialApp.title`, AppBar de inicio y encabezado del PDF |
| `android.applicationId` | Sí | Único por marca |
| `logo.primary` | Sí | PNG ≥ 512 px o SVG. Ruta relativa a la carpeta de la marca |
| `locale` | Sí | Debe estar en los idiomas soportados (inicialmente `es`, `en`) |
| `themeMode` | No | `light` (por defecto), `dark` o `system` (sigue el ajuste del dispositivo). Si es `dark` o `system`, `theme.json` debe incluir `colorDark` |
| `home.*` | No | Overrides de textos de la home; si no, se usan los del ARB |

### 7.2 `theme.json` — design system (tokens)

```json
{
  "$schema": "../_schema/theme.schema.json",
  "color": {
    "primary": "#D91C7A",
    "primaryDark": "#A81560",
    "primaryLight": "#F42C8E",
    "accent": "#FF5BA8",
    "ink": "#111827",
    "surface": "#FFFFFF",
    "surfaceMuted": "#F9FAFB",
    "border": "#E5E7EB",
    "textSecondary": "#4B5563",
    "onPrimary": "#FFFFFF",
    "success": "#1E8E5A", "successContainer": "#DCF3E6",
    "warning": "#B7791F", "warningContainer": "#FDF1D8",
    "error":   "#C0392B", "errorContainer":   "#FBE3E1",
    "info":    "#4B5FBD", "infoContainer":    "#E6E9F8"
  },
  "colorDark": {
    "primary": "#F42C8E",
    "primaryDark": "#D91C7A",
    "primaryLight": "#FF5BA8",
    "accent": "#FF7DBA",
    "ink": "#F3F4F6",
    "surface": "#1F2937",
    "surfaceMuted": "#111827",
    "border": "#374151",
    "textSecondary": "#9CA3AF",
    "onPrimary": "#FFFFFF",
    "success": "#4ADE80", "successContainer": "#14532D",
    "warning": "#FBBF24", "warningContainer": "#78350F",
    "error":   "#F87171", "errorContainer":   "#7F1D1D",
    "info":    "#93A5F5", "infoContainer":    "#1E2A5A"
  },
  "typography": {
    "fontFamilies": {
      "body":    { "family": "Montserrat",       "files": { "400": "assets/fonts/Montserrat-Regular.ttf", "600": "assets/fonts/Montserrat-SemiBold.ttf", "700": "assets/fonts/Montserrat-Bold.ttf" } },
      "display": { "family": "Playfair Display", "files": { "700": "assets/fonts/PlayfairDisplay-Bold.ttf" } }
    },
    "scale": {
      "displaySmall":  { "family": "display", "size": 36, "weight": 700 },
      "headlineSmall": { "family": "body",    "size": 24, "weight": 600 },
      "titleLarge":    { "family": "body",    "size": 22, "weight": 600 },
      "titleMedium":   { "family": "body",    "size": 16, "weight": 600 },
      "bodyMedium":    { "family": "body",    "size": 14, "weight": 400 },
      "labelLarge":    { "family": "body",    "size": 14, "weight": 600 }
    }
  },
  "radius":  { "sm": 10, "md": 12, "lg": 16, "xl": 18, "full": 999 },
  "spacing": { "xxs": 2, "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24 },
  "border":  { "width": 1 },
  "elevation": { "card": 0, "appBar": 0 },
  "components": {
    "button":     { "radius": "md", "paddingH": 24, "paddingV": 14 },
    "input":      { "radius": "md", "focusBorderWidth": 2 },
    "card":       { "radius": "lg", "bordered": true },
    "iconBadge":  { "radius": "sm", "size": 40, "sizeSmall": 32, "tintAlpha": 0.12 },
    "scanner":    { "radius": "lg", "height": 220, "heightCompact": 200, "heightSmall": 160 },
    "snackBar":   { "behavior": "floating" },
    "appBar":     { "centerTitle": false }
  },
  "layout": {
    "maxContentWidth": 620,
    "wideBreakpoint": 760,
    "compactBreakpoint": 600,
    "smallWidthBreakpoint": 360,
    "smallHeightBreakpoint": 600
  }
}
```

Reglas:

- Todos los campos de `color` son requeridos (excepto los derivables, que se calculan si faltan: `primaryDark`, `primaryLight`, `onPrimary`).
- `colorDark` tiene las mismas claves que `color`. Es requerido si `brand.themeMode` es `dark` o `system`. Tipografía, radios, espaciados y componentes son comunes a ambos modos; solo cambia la paleta.
- Los colores de los valores de ejemplo de `colorDark` son una propuesta para la marca `default` y deben validarse visualmente.
- Las fuentes se **empaquetan como assets** y se registran con `FontLoader` en el arranque. Se elimina la dependencia de `google_fonts` en runtime (en eventos la conectividad suele ser mala y hoy la primera carga descarga fuentes).
- Los valores de `default/theme.json` deben reproducir exactamente el look actual (ver tabla §2).

### 7.3 `entities.json` — esquema de BD para asistentes y staff

Cada módulo (`attendees`, `staff`) declara cómo leer, mostrar, validar y exportar sus registros.

```json
{
  "$schema": "../_schema/entities.schema.json",
  "attendees": {
    "table": "registered",
    "labels": {
      "module": "Asistentes",
      "moduleDescription": "Valida y confirma check-in de asistentes con información completa del evento.",
      "checkInTitle": "Check-in de Asistentes",
      "icon": "groups"
    },
    "identifiers": {
      "enrollmentCode": { "column": "CODIGO_INSCRIPCION", "format": "uuid_v4" },
      "rut":            { "column": "RUT" }
    },
    "checkIn": {
      "column": "CHECK_IN",
      "timestampColumn": null
    },
    "display": {
      "title": { "columns": ["NOMBRE", "APELLIDO"], "fallbackColumns": ["NOMBRE_APELLIDO"] },
      "fields": [
        { "column": "RUT",       "label": "RUT" },
        { "column": "EMAIL",     "label": "Email",     "aliases": ["CORREO"] },
        { "column": "TELEFONO",  "label": "Teléfono",  "aliases": ["TEL", "TELEFONO_CONTACTO"] },
        { "column": "DISTRITO",  "label": "Distrito" },
        { "column": "IGLESIA",   "label": "Iglesia" },
        { "column": "TALLER_AM", "label": "Taller AM" },
        { "column": "TALLER_PM", "label": "Taller PM" }
      ]
    },
    "rules": [
      {
        "id": "payment_pending",
        "type": "blockIfEquals",
        "column": "ESTADO_PAGO",
        "values": ["PENDIENTE"],
        "caseInsensitive": true,
        "message": "Pendiente de validación de pago"
      }
    ],
    "export": {
      "enabled": true,
      "title": "Listado de Asistentes",
      "mode": "allExcept",
      "excludeColumns": [
        "ID_REGISTRO", "CODIGO_INSCRIPCION", "URL_CODIGO_QR", "ESTADO_PAGO",
        "CONTACTO_PRINCIPAL", "ID_TRANSACCION_BANCARIA", "FECHA_ACTUALIZACION",
        "FECHA_INSCRIPCION", "ID_TALLER_AM", "ID_TALLER_PM"
      ],
      "columns": []
    }
  },
  "staff": {
    "table": "staff",
    "labels": {
      "module": "Staff",
      "moduleDescription": "Valida y confirma check-in del staff por RUT o código de inscripción.",
      "checkInTitle": "Check-in de Staff",
      "icon": "badge"
    },
    "identifiers": {
      "enrollmentCode": { "column": "CODIGO_INSCRIPCION", "format": "uuid_v4" },
      "rut":            { "column": "RUT" }
    },
    "checkIn": { "column": "CHECK_IN", "timestampColumn": null },
    "display": {
      "title": { "columns": ["NOMBRE", "APELLIDO"], "fallbackColumns": ["NOMBRE_APELLIDO"] },
      "fields": [
        { "column": "RUT",      "label": "RUT" },
        { "column": "EMAIL",    "label": "Email" },
        { "column": "TELEFONO", "label": "Teléfono" },
        { "column": "DISTRITO", "label": "Distrito" },
        { "column": "IGLESIA",  "label": "Iglesia" }
      ]
    },
    "rules": [
      {
        "id": "payment_pending",
        "type": "blockIfEquals",
        "column": "ESTADO_PAGO",
        "values": ["PENDIENTE"],
        "caseInsensitive": true,
        "message": "Pendiente de validación de pago"
      }
    ],
    "export": {
      "enabled": true,
      "title": "Listado de Staff",
      "mode": "allExcept",
      "excludeColumns": [
        "ID_REGISTRO", "CODIGO_INSCRIPCION", "URL_CODIGO_QR", "ESTADO_PAGO",
        "CONTACTO_PRINCIPAL", "ID_TRANSACCION_BANCARIA", "FECHA_ACTUALIZACION", "FECHA_INSCRIPCION"
      ],
      "columns": []
    }
  }
}
```

Detalle de campos:

| Campo | Requerido | Notas |
|---|---|---|
| `table` | Sí | Nombre de tabla en Supabase |
| `identifiers.enrollmentCode.column` | Sí | INV-2 |
| `identifiers.enrollmentCode.format` | No | Por defecto `uuid_v4` (comportamiento actual). Solo si un cliente lo necesita: `"format": "regex"` + `"pattern": "^EVT-[A-Z0-9]{6}$"`. El patrón debe compilar y se evalúa sobre el valor sin espacios al inicio ni al final. Para evitar ambigüedad con el RUT, el patrón no debe aceptar valores solo numéricos (ej. `26905429` o `269054298`); el validador de build lo prueba contra un set de RUTs de muestra y lo rechaza si calza con alguno |
| `identifiers.rut` | Sí | Solo `column`. El formato es fijo (INV-3a) |
| `checkIn.column` | Sí | Columna booleana que se marca en `true` |
| `checkIn.timestampColumn` | No | Si se define, en el mismo `update` se escribe `checkedInAt` en ISO 8601 UTC (columna recomendada: `timestamptz`). Hoy el parámetro se recibe pero no se persiste. Si es `null`, el comportamiento es el actual |
| `display.title` | Sí | Columnas concatenadas con espacio; `fallbackColumns` si quedan vacías |
| `display.fields[]` | Sí (≥1) | Orden = orden en la ficha. `aliases` cubre variaciones de nombre de columna. Matching case-insensitive |
| `rules[]` | No | Reglas que **bloquean** la confirmación. Tipos v1: `blockIfEquals`, `blockIfEmpty`, `blockIfFalse`. Se muestran como feedback de error al validar y deshabilitan "Confirmar" |
| `export.mode` | Sí | `allExcept` (todas las columnas menos `excludeColumns`, comportamiento actual) o `only` (solo `columns`, en ese orden) |
| `export.columns[]` | Si `mode = only` | `{ "column": "...", "label": "..." }` para encabezados legibles |
| `labels.icon` | No | Nombre de un set cerrado de íconos Material soportados (`groups`, `badge`, `person`, `event`, `school`, …) |

> En `default`, la regla `payment_pending` se replica también en staff porque hoy `isPagoPendiente` aplica a ambos módulos (si la columna no existe, la regla no bloquea).
>
> Las etiquetas de `entities.json` son texto literal en el idioma de la marca (una marca = un idioma). Los textos genéricos de la UI salen de los ARB (§8.3).

## 8. Requisitos funcionales

### 8.1 Identidad (nombre y logo)

| ID | Requisito | Prioridad |
|---|---|---|
| ID-1 | El nombre del launcher, `MaterialApp.title`, el AppBar de la home y el encabezado del PDF usan `brand.appName` | P0 |
| ID-2 | El ícono del launcher se genera por flavor desde `brands/<marca>/android/` (incluye adaptive icon si se provee foreground) | P0 |
| ID-3 | El logo reemplaza el badge `Icons.qr_code_2` de la home cuando `logo.showInHome = true` | P0 |
| ID-4 | Logo opcional en AppBar (`showInAppBar`) y en el encabezado del PDF (`showInPdf`) | P1 |
| ID-5 | Cada marca tiene `applicationId` propio; se pueden instalar varias marcas en el mismo dispositivo | P0 |

### 8.2 Design system

| ID | Requisito | Prioridad |
|---|---|---|
| DS-1 | `theme.json` se convierte en un `ThemeData` + `ThemeExtension<AppTokens>` (colores semánticos, radios, espaciados, parámetros de componentes) | P0 |
| DS-2 | Se elimina `AppColors` estático. Ningún widget referencia colores, radios ni espaciados literales; se accede vía `context.tokens` / `Theme.of(context)`. Regla de lint o test que lo verifique (grep de `Color(0x`, `BorderRadius.circular(<n>)`) | P0 |
| DS-3 | Se extraen componentes reutilizables del código actual: `AppCard`, `AppSurfaceContainer` (los `Container` con borde), `AppIconBadge`, `AppPrimaryButton`, `AppSuccessButton`, `AppOutlinedButton`, `StatusFeedbackWidget`, `ExportProgressDialog` | P0 |
| DS-4 | `Responsive` lee breakpoints y tamaños desde `layout` y `components.scanner` | P1 |
| DS-5 | Fuentes empaquetadas como assets, cargadas antes de `runApp` | P0 |
| DS-6 | Se verifica contraste mínimo WCAG AA (4.5:1) entre `primary`/`onPrimary`, `ink`/`surface` y cada estado/contenedor, **en modo claro y oscuro**, en el validador de build (warning, no error) | P2 |
| DS-7 | **Modo oscuro:** `ThemeBuilder` genera `theme` (desde `color`) y `darkTheme` (desde `colorDark`); `MaterialApp.themeMode` sale de `brand.themeMode`. `AppTokens` expone los colores del modo activo, así que ningún widget decide el color según el modo | P0 |
| DS-8 | En modo oscuro se revisan los puntos con colores fijos actuales: textos blancos en SnackBar, fondo `ink` del error de cámara, `Colors.black38` del overlay de exportación y el texto blanco del botón "Confirmar Check-in". Pasan a tokens (`onPrimary`, `onSuccess`, `scrim`, …) | P0 |
| DS-9 | Logo opcional para fondos oscuros (`logo.dark` en `brand.json`); si no existe, se usa `logo.primary` | P1 |
| DS-10 | El PDF exportado siempre usa la paleta clara (pensado para imprimir) | P0 |

### 8.3 Idioma

| ID | Requisito | Prioridad |
|---|---|---|
| L10N-1 | Todos los strings de UI, errores y PDF se mueven a ARB (`flutter gen-l10n`), con `es` como base y `en` como segundo idioma | P0 |
| L10N-2 | El idioma lo define `brand.locale`; no depende del idioma del dispositivo | P0 |
| L10N-3 | Los mensajes de error de capa data (`'Asistente no registrado'`, `'Tiempo de espera agotado'`, permisos RLS, etc.) dejan de ser strings y pasan a ser códigos (`FailureCode.notFound`, `.timeout`, `.network`, `.permissionDenied`, `.missingColumn`) que la UI traduce | P0 |
| L10N-4 | Fechas en el PDF y en la UI se formatean con `intl` según `locale` (hoy se imprime `DateTime.now()` crudo) | P1 |
| L10N-5 | Las etiquetas de los módulos y de los campos vienen de `entities.json` (texto del idioma de la marca) | P0 |

### 8.4 Esquema de datos dinámico

| ID | Requisito | Prioridad |
|---|---|---|
| DATA-1 | `Attendee` se reemplaza por una entidad genérica `Registrant { identifiers, displayTitle, fields: List<DisplayField>, checkIn: bool?, raw: Map }`. Los campos específicos (`iglesia`, `tallerAm`, …) desaparecen del dominio | P0 |
| DATA-2 | Un `RegistrantMapper` construye `Registrant` desde la fila de Supabase usando `display` y `aliases` (sustituye `AttendeeModel.fromJson`) | P0 |
| DATA-3 | `AppSupabaseClient.markCheckIn` usa `checkIn.column` y, si existe, `checkIn.timestampColumn` | P0 |
| DATA-4 | `CheckInRuleEngine` evalúa `rules[]` sobre `raw` y devuelve la primera regla que bloquea (o `null`). El BLoC usa este resultado en lugar de `isPagoPendiente` | P0 |
| DATA-5 | `AttendeeDetailsCard` renderiza `fields` dinámicamente; se elimina `showWorkshops` | P0 |
| DATA-6 | Al iniciar (o en el primer fetch), si faltan columnas declaradas se muestra un error claro con el nombre de la columna (hoy el mensaje es genérico: "La tabla no tiene una de las columnas esperadas") | P1 |
| DATA-7 | `ApiConfig` queda solo con conexión (`url`, `anonKey`, `timeoutSeconds`); tablas y columnas salen de `entities.json`. Se eliminan los `--dart-define` de tablas/columnas | P0 |

### 8.5 Check-in (núcleo, sin cambios de comportamiento)

| ID | Requisito | Prioridad |
|---|---|---|
| CI-1 | Se mantienen `UidValidator`, `Uid`, `GetAttendeeByUidUseCase` y `ConfirmCheckInUseCase` con la misma semántica (renombrados a `Registrant` donde aplique) | P0 |
| CI-1a | El RUT se valida solo por formato canónico `^\d{7,8}-[0-9K]$` (ej. `26905429-8`), sin módulo 11 (INV-3a). El código de inscripción se valida con `uuid_v4` o, si la marca lo declara, con su `pattern` | P0 |
| CI-1b | Si `checkIn.timestampColumn` está definido, la confirmación persiste `checkedInAt` junto con `checkIn.column = true` en una sola operación | P0 |
| CI-2 | Búsqueda por `enrollmentCode.column OR rut.column` y fallback tolerante de RUT, ahora con columnas desde config | P0 |
| CI-3 | Escaneo QR, anti-rebote de lectura repetida (1.200 ms), pausa de escáner durante transacción y botón "Escanear siguiente" se mantienen | P0 |
| CI-4 | Todos los tests actuales de dominio y BLoC deben seguir pasando (adaptados al rename) | P0 |

### 8.6 Exportación de listados

| ID | Requisito | Prioridad |
|---|---|---|
| EXP-1 | Ambos módulos mantienen "Descargar listado PDF" (INV-5); `export.enabled` solo existe para futuras extensiones y en v1 el validador exige `true` | P0 |
| EXP-2 | Columnas según `export.mode` / `excludeColumns` / `columns`. Se elimina la lista fija `_excludedColumns` del servicio | P0 |
| EXP-3 | Título, etiquetas de metadatos ("Tabla", "Fecha", "Total registros") y estados de progreso traducidos | P0 |
| EXP-4 | El PDF usa la fuente body y el color `primary` de la marca en encabezados de tabla; logo si `showInPdf` | P1 |
| EXP-5 | El icono del diálogo de progreso deja de depender de buscar palabras en el mensaje (`contains('consultando')`) y pasa a un enum `ExportStage` | P0 |

### 8.7 Validación de configuración

| ID | Requisito | Prioridad |
|---|---|---|
| VAL-1 | `tool/validate_brand.dart <marca>` valida los tres JSON contra `brands/_schema/*`, verifica existencia de assets, unicidad de `applicationId`, `id == carpeta`, presencia de `colorDark` cuando aplica y que un `pattern` de código de inscripción compile y no se solape con el formato RUT | P0 |
| VAL-2 | El validador corre como paso previo del build local (task de Gradle `preBuild` o script de build) y en CI para todas las marcas. El CI no necesita secretos: valida configs y corre tests, pero no compila release | P1 |
| VAL-4 | El build local falla si no existe `brands/<marca>/secrets.json` o si le falta alguna clave declarada en `secrets.example.json` | P0 |
| VAL-3 | En runtime, si la config no carga, se muestra `ConfigErrorApp` con la lista de errores (generaliza el actual `MissingConfigApp`) | P0 |

## 9. Plan de implementación por fases

| Fase | Alcance | Entregable verificable |
|---|---|---|
| 0. Base | Crear `brands/default/` replicando 1:1 la marca actual; `BrandConfig` + `BrandLoader`; flavor `default` en Gradle | La app compila con `--flavor default` y luce idéntica |
| 1. Design system | `theme.json` → `ThemeData` + `AppTokens`; extraer componentes; eliminar `AppColors` y literales; fuentes como assets; modo oscuro (`colorDark`, `themeMode`) | Golden tests en modo claro sin diferencias vs. hoy; nuevos goldens en modo oscuro |
| 2. Identidad | Nombre, logo (incluye variante oscura), ícono de launcher, `applicationId` por flavor; secretos y keystore locales por marca | Dos flavors instalados en paralelo con distinto nombre/ícono |
| 3. i18n | ARB `es`/`en`, `FailureCode`, `intl` en fechas | Marca de prueba en `en` sin strings en español |
| 4. Esquema dinámico | `Registrant`, `RegistrantMapper`, `CheckInRuleEngine`, ficha dinámica, `checkIn.column`/`timestampColumn`, `format: regex` opcional, export configurable | Marca de prueba con tabla y columnas distintas funciona sin tocar código |
| 5. Tooling | `validate_brand`, `new_brand` (scaffold, incluye `secrets.example.json`), CI de validación + tests por marca (sin secretos), README de "cómo crear una marca" | Crear una marca nueva en < 30 min siguiendo el README |

Cada fase se mergea por separado y mantiene la app funcional con la marca `default`.

## 10. Criterios de aceptación

- [ ] Con `--flavor default` la app es visual y funcionalmente idéntica a la versión actual (golden tests + prueba manual).
- [ ] Existe al menos una segunda marca de prueba (`demo`) con: otra paleta, otra tipografía, otros radios, otro logo, otro nombre, idioma `en`, tablas/columnas distintas y una regla de bloqueo distinta. Se construye **sin cambios en `lib/`**.
- [ ] Ambas marcas se instalan en paralelo en el mismo dispositivo.
- [ ] Check-in por código de inscripción y por RUT (con y sin puntos, con y sin guion, desde QR con texto adicional) funciona en ambas marcas. Todas las variantes se normalizan a `26905429-8` antes de consultar.
- [ ] Un RUT con formato inválido (ej. `2690542-98`, `26905429-X`) se rechaza sin consultar la BD. Un RUT con formato válido no se rechaza por su dígito verificador.
- [ ] Con `checkIn.timestampColumn` definido, la fila queda con `CHECK_IN = true` y la fecha/hora UTC del check-in.
- [ ] Una marca con `format: regex` acepta su código propio y sigue aceptando RUT.
- [ ] Con `themeMode: system`, la app cambia entre claro y oscuro al cambiar el ajuste del dispositivo, sin textos ilegibles ni colores fijos.
- [ ] Ningún secreto queda versionado: `git ls-files brands/` no lista ningún `secrets.json` ni keystore.
- [ ] No se puede confirmar sin validar ni confirmar un registro con `checkIn = true`.
- [ ] Una regla `blockIfEquals` configurada bloquea la confirmación y muestra su mensaje.
- [ ] La descarga de PDF funciona para asistentes y staff respetando las columnas configuradas.
- [ ] Una config inválida (color mal formado, columna faltante en `display`, asset inexistente) falla en `validate_brand` con mensaje claro.
- [ ] `grep` de `Color(0x`, `AppColors.` y `BorderRadius.circular(<número>)` en `lib/features/` devuelve 0 resultados.
- [ ] Todos los tests pasan; cobertura de `core/brand` y `CheckInRuleEngine` ≥ 90 %.

## 11. Estrategia de testing

| Tipo | Qué cubre |
|---|---|
| Unit | `BrandLoader` (configs válidas e inválidas), `ThemeBuilder` (tokens → ThemeData claro y oscuro), `RegistrantMapper` (aliases, case-insensitive, fallback de título), `CheckInRuleEngine` (cada tipo de regla), `UidValidator` (tests actuales + casos `26905429-8`, `26.905.429-8`, `269054298`, inválidos, y `pattern` personalizado) |
| BLoC | Los tests actuales de `check_in_bloc_test.dart` adaptados + casos de reglas configurables |
| Widget | Ficha dinámica con N campos; home con logo y etiquetas de marca |
| Golden | Home, check-in y ficha para `default` y `demo` en tamaños small / compact / wide, en modo claro y oscuro |
| Contrato | Test que recorre `brands/*/` y valida todas las configs contra los schemas (corre en CI) |

## 12. Riesgos

| Riesgo | Mitigación |
|---|---|
| Regresión visual de la marca actual al tokenizar | Golden tests en Fase 0 antes de tocar estilos |
| Esquemas de BD muy distintos entre clientes (ej. nombre en una sola columna, RUT sin guion en BD) | `aliases`, `fallbackColumns` y fallback de RUT; documentar formato esperado de RUT en BD |
| Fuentes de `google_fonts` hoy se descargan en runtime | Empaquetar fuentes como assets (DS-5) |
| La BD de un cliente guarda el RUT en otro formato (con puntos, sin guion) | El fallback tolerante (INV-3) cubre la búsqueda; documentar en el README que el formato recomendado en BD es `26905429-8` |
| Secretos solo locales: se pierden o difieren entre máquinas | `secrets.example.json` versionado + VAL-4; respaldar `secrets.json` y keystores en un gestor de contraseñas |
| `anon key` embebida en el APK por marca | Revisar RLS por tabla: `select` + `update` solo de la columna de check-in. Documentar políticas mínimas por marca |
| Release firmado con debug keys | Keystore por marca en Fase 2 |
| El filtro `.or('$col.eq.$uid,…')` interpola el valor | Hoy está acotado porque `uid` pasa por `UidValidator` antes; mantener esa garantía y agregar test que lo cubra |

## 13. Decisiones y preguntas abiertas

### 13.1 Decisiones tomadas

| # | Tema | Decisión | Dónde se refleja |
|---|---|---|---|
| D1 | Validación de RUT | Se mantiene la validación actual, solo de formato, sin módulo 11. Formato canónico `26905429-8` (`^\d{7,8}-[0-9K]$`) | INV-3a, CI-1a, §10, §11 |
| D2 | Formato del código de inscripción | `uuid_v4` por defecto; `format: "regex"` con patrón propio solo si un cliente lo necesita | §7.3, VAL-1, Fase 4 |
| D3 | Fecha/hora de check-in | Se persiste vía `checkIn.timestampColumn` opcional | §7.3, DATA-3, CI-1b |
| D4 | Modo oscuro | Incluido en v1: `colorDark` en `theme.json` y `themeMode` en `brand.json` | §7.1, §7.2, DS-6 a DS-10, Fase 1 |
| D5 | Secretos por marca | Gestión local (`secrets.json` y keystores gitignored); CI sin secretos | §6.1, §6.3, VAL-2, VAL-4 |

### 13.2 Preguntas abiertas

| # | Pregunta | Propuesta |
|---|---|---|
| Q5 | ¿Exportar también en CSV/Excel? | Fuera de v1 |
| Q7 | ¿El modo oscuro debe poder forzarse desde la app (toggle) o solo seguir `brand.themeMode`? | Solo `brand.themeMode` en v1 |
