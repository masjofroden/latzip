//
//  LatZip-Bridging-Header.h
//  LatZip
//
//  Integración con libarchive (listado, extracción, reconstrucción ZIP):
//  1. Añade este archivo en «Objective-C Bridging Header» del target (SWIFT_OBJC_BRIDGING_HEADER).
//  2. En «Other Linker Flags» u otra bandera equivalente, añade `-larchive`.
//  3. Los headers de libarchive (`archive.h`, `archive_entry.h`) forman parte del SDK de macOS.
//
//  Las funciones expuestas a Swift están declaradas en ArchiveEngine.h (capa C propia).
//

#import "ArchiveEngine.h"
