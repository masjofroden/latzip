//
//  ArchiveTreeBuilder.swift
//  LatZip
//

import Foundation

enum ArchiveTreeBuilder {
    /// Construye nodos raíz a partir de rutas planas devueltas por libarchive.
    static func buildTree(fromPaths paths: [(path: String, isDir: Bool, size: Int64, mtime: Date?, mode: UInt32)]) -> [ArchiveNode] {
        let root = TrieNode(name: "", fullPath: "", isDir: true)
        let sorted = paths.sorted { $0.path < $1.path }
        for item in sorted {
            let trimmed = item.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: "/").map(String.init)
            insert(into: root, components: parts, meta: item)
        }
        return trieToNodes(root)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private final class TrieNode {
        var name: String
        var fullPath: String
        var isDir: Bool
        var size: Int64 = 0
        var mtime: Date?
        var mode: UInt32 = 0
        var children: [String: TrieNode] = [:]

        init(name: String, fullPath: String, isDir: Bool) {
            self.name = name
            self.fullPath = fullPath
            self.isDir = isDir
        }
    }

    private static func insert(into parent: TrieNode, components: [String], meta: (path: String, isDir: Bool, size: Int64, mtime: Date?, mode: UInt32)) {
        guard let first = components.first else { return }
        let rest = Array(components.dropFirst())
        let pathPrefix = parent.fullPath.isEmpty ? "" : parent.fullPath + "/"
        let childPath = pathPrefix + first

        if parent.children[first] == nil {
            let impliedDir = !rest.isEmpty || meta.isDir
            parent.children[first] = TrieNode(name: first, fullPath: childPath, isDir: impliedDir)
        }

        guard let child = parent.children[first] else { return }

        if rest.isEmpty {
            child.isDir = meta.isDir
            child.size = meta.size
            child.mtime = meta.mtime
            child.mode = meta.mode
        } else {
            child.isDir = true
            insert(into: child, components: rest, meta: meta)
        }
    }

    private static func trieToNodes(_ node: TrieNode) -> [ArchiveNode] {
        node.children.values.map { child in
            let childrenNodes = trieToNodes(child).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            let isFolder = child.isDir || !childrenNodes.isEmpty
            let childList: [ArchiveNode]? = isFolder ? childrenNodes : nil
            return ArchiveNode(
                name: child.name,
                fullPath: child.fullPath,
                isFolder: isFolder,
                byteSize: child.size,
                modified: child.mtime,
                permissionsMode: child.mode,
                children: childList
            )
        }
    }
}
