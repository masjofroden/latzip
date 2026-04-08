# LatZip

**LatZip** es una app para **Mac** que te permite **abrir y revisar** archivos comprimidos (ZIP, TAR, 7z, RAR y otros) **sin tener que descomprimirlos enteros** en una carpeta. Piensa en algo cercano al Finder, con vista previa rápida y atajos para extraer solo lo que necesitas.

---

## Qué puedes hacer

- **Explorar** el contenido como si fuera una carpeta: carpetas, nombres, tamaños, fechas.
- **Extraer** lo seleccionado o **todo el archivo**, a una carpeta que elijas o **junto al archivo comprimido** (“extraer aquí”).
- **Vista previa** de archivos con Quick Look cuando tiene sentido.
- **Editar archivos comprimidos**: añadir archivos o carpetas en **ZIP, TAR (incl. `.tar.gz`, `.tar.bz2`, `.tar.xz`), 7z, GZIP, BZIP2 o XZ** cuando el sistema lo permita vía libarchive; **proteger con contraseña** solo en **ZIP** (reescritura cifrada).
- **Pestañas**, **recientes** y **favoritos** para volver rápido a lo que usas a menudo.
- **Varios idiomas**: interfaz en **español** e **inglés** (y la opción de seguir el idioma del sistema).
- **Archivo comprimido nuevo**: crea un contenedor vacío (⌘ N) en el formato que elijas en el panel de guardado y ábrelo para añadir archivos.
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
| **Apariencia** | *Según el sistema*, **claro** u **oscuro**. Con la opción del sistema, LatZip sigue el modo claro/oscuro de macOS. |
| **Ayuda — atajos** | Botón que abre la misma guía que **Ayuda → Atajos de teclado…** (útil con solo la ventana de ajustes abierta). |
| **Seguridad — Llavero** | Opción para **guardar contraseñas de archivos cifrados** en el Llavero de macOS (por ruta de archivo); en la hoja de desbloqueo puedes marcar guardar para ese archivo. |

---

## Cómo abrir un archivo

1. Arrastra el `.zip` (u otro comprimido) a la ventana de LatZip, o  
2. **Archivo → Abrir archivo comprimido…** (⌘ O), o  
3. Clic derecho en el Finder → **Abrir con** → LatZip (si lo tienes asociado).  
4. **Finder → Servicios → Open with LatZip** (tras instalar o compilar, puede hacer falta activar el servicio en **Ajustes del Sistema → Teclado → Atajos de teclado → Servicios**).

---

## Atajos útiles

| Acción | Atajo |
|--------|--------|
| Archivo comprimido nuevo… | ⌘ N |
| Abrir archivo comprimido… | ⌘ O |

## Atajos del menú “Archivo comprimido”

| Acción | Atajo |
|--------|--------|
| Extraer a carpeta… | ⌘ E |
| Extraer aquí | ⌘ ⇧ H |
| Extraer todo a carpeta… | ⌘ ⇧ E |
| Extraer todo aquí | ⌘ ⌥ E |
| Añadir archivos… (formatos editables) | ⌘ ⇧ A |
| Proteger con contraseña… (solo ZIP) | ⌘ ⇧ P |

Los comandos aplican a la **pestaña activa**.

---

## Desempaquetado y formatos «solo lectura»

LatZip usa **libarchive** del sistema para listar y extraer. Eso cubre bien **ZIP, TAR y variantes, 7z, RAR/RAR5 (según compilación), ISO 9660, CPIO, AR, CAB, LHA/LZH, XAR, RPM (filtro), DEB, WARC, compresión gzip/bzip2/xz/lzma/zstd, Unix compress (`.Z`)**, etc.

Lista que a veces se asocia a herramientas tipo **7-Zip** (APFS, ARJ, CHM, CramFS, **DMG**, filesystems **EXT/FAT/NTFS/HFS**, imágenes **GPT/MBR** «crudas», **NSIS**, **QCOW2/VDI/VHD/VHDX/VMDK**, **SquashFS**, **UDF/UEFI** en forma de volúmen crudo, **MSI** como instalador, etc.): **no** están implementados como lectores propios en libarchive en el sentido de «abrir como archivo y ver árbol de ficheros». Montar o interpretar esos formatos haría falta **otros motores, APIs del sistema o utilidades externas**, y hoy LatZip **no** los registra en el Finder para evitar «Abrir con → LatZip» en ficheros que van a fallar.

Si en el futuro integráis binarios auxiliares (p. ej. `7zz`) o extensiones **File Provider**, se podría ampliar la lista con cuidado y mensajes de error claros.

### Cifrado al proteger un ZIP

La acción **Proteger con contraseña** pide a libarchive **`zip:encryption=aes256`** (WinZip-compatible **AES-256**). Si el `libarchive` enlazado no lo admite, la operación falla con un mensaje explícito (no se usa cifrado Zip tradicional como sustituto silencioso).

---

## Limitaciones (transparentes)

- No es un clon de WinRAR/BetterZip en cada detalle; el foco es **explorar y extraer con seguridad**.
- Algunos metadatos finos (p. ej. tamaño comprimido por entrada) pueden no mostrarse.
- **RAR** e **ISO** suelen ser **solo lectura e extracción** (según las capacidades del libarchive del SDK). **RAR con contraseña** puede no abrirse. Crear **RAR** no está soportado.

---

## Para desarrolladores

- Código en **Swift** y **SwiftUI**, motor de lectura/extracción vía **libarchive** (SDK de Apple).
- Abre **`LatZip.xcodeproj`** en **Xcode 15+**, esquema **LatZip**, destino *My Mac*.
- **CI:** con GitHub Actions, el workflow `.github/workflows/ci.yml` ejecuta `xcodebuild test` en cada push/PR a `main` o `master`.
- Tests: **Product → Test** (⌘ U) o  
  `xcodebuild -scheme LatZip -destination 'platform=macOS' test`  
  Incluye pruebas del puente C (`archive_engine_*`) y lectura de ZIP/TAR generados con `/usr/bin/zip` y `/usr/bin/tar` cuando existan en el sistema.
- Estructura interna: MVVM, servicios (`ArchiveReaderService`, `ArchiveExtractionService`, …), **design system** en `LatZip/DesignSystem/`, puente C en `CBridge/`.
- **Licencia:** el código de LatZip se distribuye bajo la **licencia MIT** (© 2026 LatZip contributors). El texto legal completo está en [`LICENSE`](LICENSE).

Cabeceras de referencia **libarchive 3.7.7** en `LatZip/Vendor/libarchive/`; el binario se enlaza con **`-larchive`**.

**Consola de Xcode:** mensajes *Invalid content type … Quicklook* (Help, Affinity, Tips, etc.) salen de **extensiones del sistema**, no de LatZip. Tras abrir la **vista previa** (Quick Look), líneas de *WebContent* / *sandbox* / *pasteboard* son habituales si el generador usa WebKit; muchas veces es ruido y no indica fallo de la UI de LatZip.

---

## Licencias y RAR

La lectura de muchos formatos (incl. RAR cuando el sistema lo permite) depende de **libarchive** del SDK. **libunrar** tiene otras condiciones de licencia si algún día se integrara aparte.
