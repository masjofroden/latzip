//
//  ArchiveEngine.h
//  LatZip
//
//  Capa C sobre libarchive: listado (con passphrase opcional), extracción y ZIP con rutas internas.
//

#ifndef ArchiveEngine_h
#define ArchiveEngine_h

#include <stddef.h>

/** `archive_engine_zip_apply_passphrase`: libarchive rechazó `zip:encryption=aes256` (no hay cifrado Zip tradicional). */
#define LATZIP_ERR_ZIP_AES256_UNAVAILABLE (-60)
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char *pathname;
    int64_t size;
    int is_dir;
    int64_t mtime_sec;
    uint32_t mode;
} ArchiveEntryInfo;

typedef struct {
    ArchiveEntryInfo *entries;
    size_t count;
    char *format_name;
    char *filter_name;
} ArchiveListResult;

/// `passphrase` puede ser NULL. `error_message` opcional (UTF-8).
int archive_engine_list(
    const char *archive_path,
    const char *passphrase,
    ArchiveListResult *out,
    char *error_message,
    size_t error_message_capacity
);

void archive_engine_list_free(ArchiveListResult *result);

/// Extracción de subárbol de carpeta.
int archive_engine_extract_selection(
    const char *archive_path,
    const char *passphrase,
    const char *selection_path,
    int is_directory,
    const char *output_dir,
    char *error_message,
    size_t error_message_capacity
);

/// Un solo archivo a ruta de destino completa.
int archive_engine_extract_file_to_path(
    const char *archive_path,
    const char *passphrase,
    const char *entry_path,
    const char *output_file_path,
    char *error_message,
    size_t error_message_capacity
);

typedef struct {
    const char *filesystem_path;
    const char *archive_internal_path;
} ArchiveZipAddPair;

/// Crea un archivo comprimido vacío según la extensión de `zip_path` (p. ej. `.zip`, `.tar`, `.7z`, `.tar.gz`).
int archive_engine_zip_create_empty(
    const char *zip_path,
    char *error_message,
    size_t error_message_capacity
);

/// Añade ficheros al archivo reempaquetando según la extensión de la ruta (ZIP, tar.*, 7z, etc.).
int archive_engine_zip_add_paths(
    const char *zip_path,
    const ArchiveZipAddPair *pairs,
    size_t pair_count,
    char *error_message,
    size_t error_message_capacity
);

/// Reempaqueta el ZIP cifrando entradas con `new_passphrase`. `read_passphrase` si el ZIP ya estaba cifrado.
int archive_engine_zip_apply_passphrase(
    const char *zip_path,
    const char *read_passphrase,
    const char *new_passphrase,
    char *error_message,
    size_t error_message_capacity
);

/// Ruta cuyo sufijo es un formato que LatZip permite crear o modificar (libarchive `format_filter_by_ext`).
int archive_engine_is_editable_archive_path(const char *archive_path);

/// Solo `.zip` (contraseña / cifrado ZIP).
int archive_engine_is_zip_extension(const char *archive_path);

#ifdef __cplusplus
}
#endif

#endif /* ArchiveEngine_h */
