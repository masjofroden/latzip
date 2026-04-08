//
//  ArchiveEngine.c
//  LatZip
//

#include "ArchiveEngine.h"
#include <archive.h>
#include <archive_entry.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static void set_error_message(char *buf, size_t cap, const char *msg) {
    if (!buf || cap == 0) return;
    snprintf(buf, cap, "%s", msg ? msg : "unknown error");
}

static void copy_engine_error(struct archive *a, char *buf, size_t cap) {
    if (!buf || cap == 0) return;
    const char *e = archive_error_string(a);
    set_error_message(buf, cap, e ? e : "archive error");
}

static int open_archive_reader(struct archive **out, const char *path, const char *passphrase, char *err, size_t errlen) {
    struct archive *a = archive_read_new();
    if (!a) {
        set_error_message(err, errlen, "out of memory");
        return -ENOMEM;
    }
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);
    if (passphrase && passphrase[0]) {
        if (archive_read_add_passphrase(a, passphrase) != ARCHIVE_OK) {
            copy_engine_error(a, err, errlen);
            archive_read_free(a);
            return ARCHIVE_FAILED;
        }
    }
    if (archive_read_open_filename(a, path, 10240) != ARCHIVE_OK) {
        copy_engine_error(a, err, errlen);
        archive_read_free(a);
        return ARCHIVE_FAILED;
    }
    *out = a;
    return ARCHIVE_OK;
}

/// Rechaza path traversal y rutas absolutas dentro del archivo.
static int internal_entry_path_is_unsafe(const char *path) {
    if (!path || path[0] == '\0') return 1;
    if (path[0] == '/') return 1;
    const char *p = path;
    const char *end = path + strlen(path);
    while (p < end) {
        const char *slash = strchr(p, '/');
        size_t len = slash ? (size_t)(slash - p) : (size_t)(end - p);
        if (len == 2 && p[0] == '.' && p[1] == '.') return 1;
        if (len == 1 && p[0] == '.') {
            /* permitir . como componente aislado es raro; lo tratamos como inseguro */
        }
        if (!slash) break;
        p = slash + 1;
    }
    if (strstr(path, "/../") != NULL || strstr(path, "../") == path) return 1;
    size_t n = strlen(path);
    if (n >= 3 && strcmp(path + n - 3, "/..") == 0) return 1;
    return 0;
}

static int copy_archive_data(struct archive *ar, struct archive *aw) {
    int r;
    const void *buff;
    size_t size;
    la_int64_t offset;

    for (;;) {
        r = (int)archive_read_data_block(ar, &buff, &size, &offset);
        if (r == ARCHIVE_EOF) return ARCHIVE_OK;
        if (r != ARCHIVE_OK) return r;
        r = (int)archive_write_data_block(aw, buff, size, offset);
        if (r != ARCHIVE_OK && r != ARCHIVE_WARN) return r;
    }
}

static int path_matches_selection(const char *pathname, const char *selection, int is_dir) {
    if (!pathname || !selection) return 0;
    if (internal_entry_path_is_unsafe(pathname) || internal_entry_path_is_unsafe(selection)) return 0;
    size_t slen = strlen(selection);
    size_t plen = strlen(pathname);
    if (strcmp(pathname, selection) == 0) return 1;
    if (!is_dir) return 0;
    if (slen > 0 && selection[slen - 1] == '/') {
        if (strncmp(pathname, selection, slen) == 0) return 1;
    } else {
        if (plen > slen && pathname[slen] == '/' && strncmp(pathname, selection, slen) == 0) return 1;
    }
    return 0;
}

static void ensure_dir_for_file(const char *filepath) {
    const char *last = strrchr(filepath, '/');
    if (!last || last == filepath) return;
    size_t len = (size_t)(last - filepath);
    char *dir = malloc(len + 1);
    if (!dir) return;
    memcpy(dir, filepath, len);
    dir[len] = '\0';
    for (char *p = dir + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            mkdir(dir, 0755);
            *p = '/';
        }
    }
    mkdir(dir, 0755);
    free(dir);
}

int archive_engine_list(
    const char *archive_path,
    const char *passphrase,
    ArchiveListResult *out,
    char *error_message,
    size_t error_message_capacity
) {
    if (!archive_path || !out) return -EINVAL;
    memset(out, 0, sizeof(*out));
    if (error_message && error_message_capacity) error_message[0] = '\0';

    struct archive *a = NULL;
    int open_rc = open_archive_reader(&a, archive_path, passphrase, error_message, error_message_capacity);
    if (open_rc != ARCHIVE_OK) return open_rc;

    const char *fmt = archive_format_name(a);
    out->format_name = strdup(fmt && fmt[0] ? fmt : "");
    const char *flt = archive_filter_name(a, 0);
    out->filter_name = strdup(flt && flt[0] ? flt : "");

    struct archive_entry *entry = archive_entry_new();
    if (!entry) {
        free(out->format_name);
        free(out->filter_name);
        out->format_name = NULL;
        out->filter_name = NULL;
        archive_read_close(a);
        archive_read_free(a);
        return -ENOMEM;
    }

    size_t cap = 64;
    out->entries = calloc(cap, sizeof(ArchiveEntryInfo));
    if (!out->entries) {
        archive_entry_free(entry);
        archive_read_close(a);
        archive_read_free(a);
        free(out->format_name);
        free(out->filter_name);
        out->format_name = NULL;
        out->filter_name = NULL;
        return -ENOMEM;
    }

    int header_r;
    while ((header_r = archive_read_next_header2(a, entry)) == ARCHIVE_OK) {
        const char *path = archive_entry_pathname_utf8(entry);
        if (!path) path = archive_entry_pathname(entry);
        if (!path) {
            archive_read_data_skip(a);
            continue;
        }
        if (internal_entry_path_is_unsafe(path)) {
            archive_read_data_skip(a);
            continue;
        }

        if (out->count >= cap) {
            size_t ncap = cap * 2;
            ArchiveEntryInfo *ne = realloc(out->entries, ncap * sizeof(ArchiveEntryInfo));
            if (!ne) break;
            memset(ne + cap, 0, (ncap - cap) * sizeof(ArchiveEntryInfo));
            out->entries = ne;
            cap = ncap;
        }

        ArchiveEntryInfo *info = &out->entries[out->count];
        info->pathname = strdup(path);
        info->size = archive_entry_size(entry);
        info->is_dir = archive_entry_filetype(entry) == AE_IFDIR ? 1 : 0;
        info->mtime_sec = (int64_t)archive_entry_mtime(entry);
        info->mode = (uint32_t)archive_entry_mode(entry);
        out->count++;
        archive_read_data_skip(a);
    }

    if (header_r != ARCHIVE_EOF) {
        copy_engine_error(a, error_message, error_message_capacity);
    }
    archive_entry_free(entry);
    archive_read_close(a);
    archive_read_free(a);

    if (header_r != ARCHIVE_EOF) {
        archive_engine_list_free(out);
        memset(out, 0, sizeof(*out));
        return header_r;
    }

    return 0;
}

void archive_engine_list_free(ArchiveListResult *result) {
    if (!result) return;
    if (result->entries) {
        for (size_t i = 0; i < result->count; i++) {
            free(result->entries[i].pathname);
        }
        free(result->entries);
        result->entries = NULL;
    }
    result->count = 0;
    free(result->format_name);
    result->format_name = NULL;
    free(result->filter_name);
    result->filter_name = NULL;
}

int archive_engine_extract_file_to_path(
    const char *archive_path,
    const char *passphrase,
    const char *entry_path,
    const char *output_file_path,
    char *error_message,
    size_t error_message_capacity
) {
    if (!archive_path || !entry_path || !output_file_path) return -EINVAL;
    if (error_message && error_message_capacity) error_message[0] = '\0';
    if (internal_entry_path_is_unsafe(entry_path)) {
        set_error_message(error_message, error_message_capacity, "unsafe entry path");
        return -EINVAL;
    }

    struct archive *a = NULL;
    int o = open_archive_reader(&a, archive_path, passphrase, error_message, error_message_capacity);
    if (o != ARCHIVE_OK) return o;

    struct archive *ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS | ARCHIVE_EXTRACT_XATTR);

    struct archive_entry *entry = archive_entry_new();
    int found = 0;
    int ret = ARCHIVE_OK;

    while (archive_read_next_header2(a, entry) == ARCHIVE_OK) {
        const char *path = archive_entry_pathname_utf8(entry);
        if (!path) path = archive_entry_pathname(entry);
        if (!path || internal_entry_path_is_unsafe(path)) {
            archive_read_data_skip(a);
            continue;
        }
        if (strcmp(path, entry_path) != 0) {
            archive_read_data_skip(a);
            continue;
        }
        found = 1;
        archive_entry_set_pathname(entry, output_file_path);
        archive_entry_set_hardlink(entry, NULL);
        archive_entry_set_symlink(entry, NULL);
        ensure_dir_for_file(output_file_path);
        ret = archive_write_header(ext, entry);
        if (ret == ARCHIVE_OK) {
            ret = copy_archive_data(a, ext);
            if (ret == ARCHIVE_EOF) ret = ARCHIVE_OK;
        }
        archive_write_finish_entry(ext);
        if (ret != ARCHIVE_OK) copy_engine_error(a, error_message, error_message_capacity);
        break;
    }

    archive_entry_free(entry);
    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    return found ? (ret == ARCHIVE_OK ? 0 : ret) : -ENOENT;
}

int archive_engine_extract_selection(
    const char *archive_path,
    const char *passphrase,
    const char *selection_path,
    int is_directory,
    const char *output_dir,
    char *error_message,
    size_t error_message_capacity
) {
    if (!archive_path || !selection_path || !output_dir) return -EINVAL;
    if (error_message && error_message_capacity) error_message[0] = '\0';
    if (internal_entry_path_is_unsafe(selection_path)) {
        set_error_message(error_message, error_message_capacity, "unsafe selection path");
        return -EINVAL;
    }

    if (!is_directory) {
        char *base = strrchr(selection_path, '/');
        const char *name = base ? base + 1 : selection_path;
        size_t olen = strlen(output_dir);
        char *outfile = malloc(olen + strlen(name) + 2);
        if (!outfile) return -ENOMEM;
        snprintf(outfile, olen + strlen(name) + 2, "%s/%s", output_dir, name);
        int r = archive_engine_extract_file_to_path(archive_path, passphrase, selection_path, outfile, error_message, error_message_capacity);
        free(outfile);
        return r;
    }

    struct archive *a = NULL;
    int o = open_archive_reader(&a, archive_path, passphrase, error_message, error_message_capacity);
    if (o != ARCHIVE_OK) return o;

    struct archive *ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS | ARCHIVE_EXTRACT_XATTR);

    struct archive_entry *entry = archive_entry_new();
    struct archive_entry *out_entry = archive_entry_new();
    size_t odir_len = strlen(output_dir);
    int ret = 0;

    while (archive_read_next_header2(a, entry) == ARCHIVE_OK) {
        const char *path = archive_entry_pathname_utf8(entry);
        if (!path) path = archive_entry_pathname(entry);
        if (!path || internal_entry_path_is_unsafe(path)) {
            archive_read_data_skip(a);
            continue;
        }
        if (!path_matches_selection(path, selection_path, 1)) {
            archive_read_data_skip(a);
            continue;
        }

        const char *rel = path;
        size_t slen = strlen(selection_path);
        if (strncmp(path, selection_path, slen) == 0) {
            rel = path + slen;
            while (*rel == '/') rel++;
        }
        if (internal_entry_path_is_unsafe(rel)) {
            archive_read_data_skip(a);
            continue;
        }

        size_t rel_len = strlen(rel);
        char *full_out = malloc(odir_len + rel_len + 4);
        if (!full_out) {
            ret = -ENOMEM;
            break;
        }
        if (rel_len == 0) {
            snprintf(full_out, odir_len + 4, "%s", output_dir);
        } else {
            snprintf(full_out, odir_len + rel_len + 4, "%s/%s", output_dir, rel);
        }

        archive_entry_free(out_entry);
        out_entry = archive_entry_clone(entry);
        if (!out_entry) {
            free(full_out);
            ret = -ENOMEM;
            break;
        }
        archive_entry_set_pathname(out_entry, full_out);
        archive_entry_set_hardlink(out_entry, NULL);
        if (archive_entry_filetype(entry) != AE_IFLNK) {
            archive_entry_set_symlink(out_entry, NULL);
        } else {
            const char *link = archive_entry_symlink_utf8(entry);
            if (!link) link = archive_entry_symlink(entry);
            if (link) archive_entry_set_symlink(out_entry, link);
        }

        ensure_dir_for_file(full_out);
        int wr = archive_write_header(ext, out_entry);
        if (wr != ARCHIVE_OK) {
            free(full_out);
            archive_read_data_skip(a);
            continue;
        }
        if (archive_entry_filetype(entry) != AE_IFDIR) {
            wr = copy_archive_data(a, ext);
            if (wr != ARCHIVE_OK && wr != ARCHIVE_EOF) ret = wr;
        } else {
            archive_read_data_skip(a);
        }
        archive_write_finish_entry(ext);
        free(full_out);
    }

    archive_entry_free(entry);
    archive_entry_free(out_entry);
    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);
    return ret;
}

static int copy_one_entry_reader_to_writer(struct archive *ar, struct archive *aw, struct archive_entry *entry) {
    int r = archive_write_header(aw, entry);
    if (r != ARCHIVE_OK) return r;
    if (archive_entry_size(entry) > 0 || archive_entry_filetype(entry) == AE_IFREG) {
        r = copy_archive_data(ar, aw);
        if (r == ARCHIVE_EOF) r = ARCHIVE_OK;
    }
    return archive_write_finish_entry(aw);
}

int archive_engine_zip_add_paths(
    const char *zip_path,
    const ArchiveZipAddPair *pairs,
    size_t pair_count,
    char *error_message,
    size_t error_message_capacity
) {
    if (!zip_path || !pairs || pair_count == 0) {
        set_error_message(error_message, error_message_capacity, "invalid arguments");
        return -EINVAL;
    }
    if (error_message && error_message_capacity) error_message[0] = '\0';

    for (size_t i = 0; i < pair_count; i++) {
        if (pairs[i].archive_internal_path && internal_entry_path_is_unsafe(pairs[i].archive_internal_path)) {
            set_error_message(error_message, error_message_capacity, "unsafe archive path");
            return -EINVAL;
        }
    }

    char tmpl[] = "/tmp/latzip_zip_XXXXXX";
    int fd = mkstemp(tmpl);
    if (fd < 0) {
        set_error_message(error_message, error_message_capacity, "mkstemp failed");
        return -1;
    }
    close(fd);

    struct archive *in = archive_read_new();
    archive_read_support_filter_all(in);
    archive_read_support_format_all(in);
    if (archive_read_open_filename(in, zip_path, 10240) != ARCHIVE_OK) {
        unlink(tmpl);
        copy_engine_error(in, error_message, error_message_capacity);
        archive_read_free(in);
        return ARCHIVE_FAILED;
    }

    struct archive *out = archive_write_new();
    archive_write_set_format_zip(out);
    if (archive_write_open_filename(out, tmpl) != ARCHIVE_OK) {
        copy_engine_error(out, error_message, error_message_capacity);
        archive_read_close(in);
        archive_read_free(in);
        archive_write_free(out);
        unlink(tmpl);
        return ARCHIVE_FAILED;
    }

    struct archive_entry *entry = archive_entry_new();
    int fail = 0;

    while (archive_read_next_header2(in, entry) == ARCHIVE_OK) {
        int r = copy_one_entry_reader_to_writer(in, out, entry);
        if (r != ARCHIVE_OK) {
            fail = 1;
            break;
        }
        archive_entry_clear(entry);
    }

    struct archive *disk = archive_read_disk_new();
    archive_read_disk_set_standard_lookup(disk);

    for (size_t i = 0; i < pair_count && !fail; i++) {
        const char *src = pairs[i].filesystem_path;
        const char *internal = pairs[i].archive_internal_path;
        if (!src || !internal) {
            fail = 1;
            break;
        }

        archive_read_disk_open(disk, src);
        archive_entry_clear(entry);
        if (archive_read_next_header2(disk, entry) != ARCHIVE_OK) {
            archive_read_close(disk);
            continue;
        }
        archive_entry_set_pathname(entry, internal);
        archive_entry_set_hardlink(entry, NULL);
        int r = copy_one_entry_reader_to_writer(disk, out, entry);
        archive_read_close(disk);
        if (r != ARCHIVE_OK) fail = 1;
    }

    archive_read_free(disk);
    archive_entry_free(entry);
    archive_read_close(in);
    archive_read_free(in);
    archive_write_close(out);
    archive_write_free(out);

    if (fail) {
        unlink(tmpl);
        set_error_message(error_message, error_message_capacity, "copy failed");
        return -1;
    }

    if (rename(tmpl, zip_path) != 0) {
        set_error_message(error_message, error_message_capacity, "rename failed");
        unlink(tmpl);
        return -1;
    }

    return 0;
}

int archive_engine_zip_apply_passphrase(
    const char *zip_path,
    const char *read_passphrase,
    const char *new_passphrase,
    char *error_message,
    size_t error_message_capacity
) {
    if (!zip_path || !new_passphrase || new_passphrase[0] == '\0') {
        set_error_message(error_message, error_message_capacity, "invalid arguments");
        return -EINVAL;
    }
    if (error_message && error_message_capacity) error_message[0] = '\0';

    char tmpl[] = "/tmp/latzip_zp_XXXXXX";
    int fd = mkstemp(tmpl);
    if (fd < 0) {
        set_error_message(error_message, error_message_capacity, "mkstemp failed");
        return -1;
    }
    close(fd);

    struct archive *in = NULL;
    if (open_archive_reader(&in, zip_path, read_passphrase, error_message, error_message_capacity) != ARCHIVE_OK) {
        unlink(tmpl);
        return -1;
    }

    struct archive *out = archive_write_new();
    if (!out) {
        set_error_message(error_message, error_message_capacity, "out of memory");
        archive_read_close(in);
        archive_read_free(in);
        unlink(tmpl);
        return -ENOMEM;
    }
    archive_write_set_format_zip(out);
    if (archive_write_set_passphrase(out, new_passphrase) != ARCHIVE_OK) {
        copy_engine_error(out, error_message, error_message_capacity);
        archive_read_close(in);
        archive_read_free(in);
        archive_write_free(out);
        unlink(tmpl);
        return ARCHIVE_FAILED;
    }
    /* Cifrado ZIP (AES-256 si está disponible; si no, tradicional). */
    if (archive_write_set_options(out, "zip:encryption=aes256") != ARCHIVE_OK) {
        archive_clear_error(out);
        if (archive_write_set_options(out, "zip:encryption=traditional") != ARCHIVE_OK) {
            archive_clear_error(out);
        }
    }

    if (archive_write_open_filename(out, tmpl) != ARCHIVE_OK) {
        copy_engine_error(out, error_message, error_message_capacity);
        archive_read_close(in);
        archive_read_free(in);
        archive_write_free(out);
        unlink(tmpl);
        return ARCHIVE_FAILED;
    }

    struct archive_entry *entry = archive_entry_new();
    if (!entry) {
        set_error_message(error_message, error_message_capacity, "out of memory");
        archive_read_close(in);
        archive_read_free(in);
        archive_write_close(out);
        archive_write_free(out);
        unlink(tmpl);
        return -ENOMEM;
    }

    int fail = 0;
    while (archive_read_next_header2(in, entry) == ARCHIVE_OK) {
        int r = copy_one_entry_reader_to_writer(in, out, entry);
        if (r != ARCHIVE_OK) {
            fail = 1;
            break;
        }
        archive_entry_clear(entry);
    }

    archive_entry_free(entry);
    archive_read_close(in);
    archive_read_free(in);
    archive_write_close(out);
    archive_write_free(out);

    if (fail) {
        unlink(tmpl);
        set_error_message(error_message, error_message_capacity, "repack failed");
        return -1;
    }

    if (rename(tmpl, zip_path) != 0) {
        set_error_message(error_message, error_message_capacity, "rename failed");
        unlink(tmpl);
        return -1;
    }

    return 0;
}

int archive_engine_zip_create_empty(
    const char *zip_path,
    char *error_message,
    size_t error_message_capacity
) {
    if (!zip_path) {
        set_error_message(error_message, error_message_capacity, "invalid arguments");
        return -EINVAL;
    }
    if (error_message && error_message_capacity) error_message[0] = '\0';

    struct archive *out = archive_write_new();
    archive_write_set_format_zip(out);
    if (archive_write_open_filename(out, zip_path) != ARCHIVE_OK) {
        copy_engine_error(out, error_message, error_message_capacity);
        archive_write_free(out);
        return ARCHIVE_FAILED;
    }
    archive_write_close(out);
    archive_write_free(out);
    return 0;
}

int archive_engine_is_zip_extension(const char *archive_path) {
    if (!archive_path) return 0;
    size_t len = strlen(archive_path);
    if (len < 4) return 0;
    const char *ext = archive_path + len - 4;
    return strcasecmp(ext, ".zip") == 0;
}
