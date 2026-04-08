# LatZip

**LatZip** es una app para **Mac** que te permite **abrir y revisar** archivos comprimidos (ZIP, TAR, 7z, RAR y otros) **sin tener que descomprimirlos enteros** en una carpeta. Piensa en algo cercano al Finder, con vista previa rápida y atajos para extraer solo lo que necesitas.

---

## Qué puedes hacer

- **Explorar** el contenido como si fuera una carpeta: carpetas, nombres, tamaños, fechas.
- **Extraer** lo seleccionado o **todo el archivo**, a una carpeta que elijas o **junto al archivo comprimido** (“extraer aquí”).
- **Vista previa** de archivos con Quick Look cuando tiene sentido.
- **Editar ZIP**: añadir archivos o carpetas y **proteger con contraseña** (los demás formatos suelen ser solo lectura).
- **Pestañas**, **recientes** y **favoritos** para volver rápido a lo que usas a menudo.
- **Varios idiomas**: interfaz en **español** e **inglés** (y la opción de seguir el idioma del sistema).
- **ZIP vacío nuevo**: crea un `.zip` vacío (⌘ N o botón en la pantalla de bienvenida) y ábrelo para añadir archivos.
- **Arrastrar al Finder**: desde la lista, arrastra archivos o carpetas del archivo comprimido al Escritorio o a una carpeta (se generan copias temporales; con varios elementos seleccionados se exporta una carpeta con la estructura de rutas internas).

---

## Requisitos

- **macOS 13.5** o posterior  
- Mac con **Apple Silicon** o **Intel**

---

## Ajustes útiles (⌘ ,)

En **LatZip → Ajustes** (o **⌘ ,**) puedes configurar:

| Opción | Qué hace |
|--------|----------|
| **Extracción — si el archivo ya existe** | Valor por defecto: *reemplazar*, *omitir* o *conservar ambos (renombrar)*. |
| **Panel si hay conflicto** | Si al extraer **ya hay algo en el destino**, la app te pregunta **una vez** qué hacer en **esa** extracción; la tecla **Retorno** confirma la opción que tengas por defecto en Ajustes. |
| **Idioma** | *Según el sistema*, *inglés* o *español*. Al cambiarlo, la app **se reinicia sola** para aplicar el idioma. |

---

## Cómo abrir un archivo

1. Arrastra el `.zip` (u otro comprimido) a la ventana de LatZip, o  
2. **Archivo → Abrir archivo comprimido…** (⌘ O), o  
3. Clic derecho en el Finder → **Abrir con** → LatZip (si lo tienes asociado).

---

## Atajos útiles

| Acción | Atajo |
|--------|--------|
| ZIP vacío nuevo… | ⌘ N |
| Abrir archivo comprimido… | ⌘ O |

## Atajos del menú “Archivo comprimido”

| Acción | Atajo |
|--------|--------|
| Extraer a carpeta… | ⌘ E |
| Extraer aquí | ⌘ ⇧ H |
| Extraer todo a carpeta… | ⌘ ⇧ E |
| Extraer todo aquí | ⌘ ⌥ E |
| Añadir archivos… (ZIP) | ⌘ ⇧ A |
| Proteger con contraseña… (ZIP) | ⌘ ⇧ P |

Los comandos aplican a la **pestaña activa**.

---

## Limitaciones (transparentes)

- No es un clon de WinRAR/BetterZip en cada detalle; el foco es **explorar y extraer con seguridad**.
- Algunos metadatos finos (p. ej. tamaño comprimido por entrada) pueden no mostrarse.
- Crear o escribir formatos distintos de **ZIP** no está soportado en esta versión.

---

## Para desarrolladores

- Código en **Swift** y **SwiftUI**, motor de lectura/extracción vía **libarchive** (SDK de Apple).
- Abre **`LatZip.xcodeproj`** en **Xcode 15+**, esquema **LatZip**, destino *My Mac*.
- **CI:** con GitHub Actions, el workflow `.github/workflows/ci.yml` ejecuta `xcodebuild test` en cada push/PR a `main` o `master`.
- Tests: **Product → Test** (⌘ U) o  
  `xcodebuild -scheme LatZip -destination 'platform=macOS' test`
- Estructura interna: MVVM, servicios (`ArchiveReaderService`, `ArchiveExtractionService`, …), **design system** en `LatZip/DesignSystem/`, puente C en `CBridge/`.
- **Licencia:** el código de LatZip se distribuye bajo la **licencia MIT** (© 2026 LatZip contributors). El texto legal completo está en [`LICENSE`](LICENSE).

Cabeceras de referencia **libarchive 3.7.7** en `LatZip/Vendor/libarchive/`; el binario se enlaza con **`-larchive`**.

---

## Licencias y RAR

La lectura de muchos formatos (incl. RAR cuando el sistema lo permite) depende de **libarchive** del SDK. **libunrar** tiene otras condiciones de licencia si algún día se integrara aparte.
