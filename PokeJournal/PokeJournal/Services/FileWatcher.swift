//
//  FileWatcher.swift
//  PokéJournal
//

import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: Int32
    private let url: URL
    private let onChange: () -> Void

    init?(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            return nil
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            self?.onChange()
        }

        source?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
        }

        source?.resume()
    }

    deinit {
        source?.cancel()
    }
}

@Observable
final class DirectoryWatcher {
    private var watchers: [FileWatcher] = []
    private var directoryWatcher: FileWatcher?
    private let directory: URL
    private let onChange: () -> Void

    init(directory: URL, onChange: @escaping () -> Void) {
        self.directory = directory
        self.onChange = onChange
        setupWatchers()
    }

    private func setupWatchers() {
        directoryWatcher = FileWatcher(url: directory) { [weak self] in
            self?.onChange()
            self?.setupWatchers()
        }

        watchers.removeAll()

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }

            if let watcher = FileWatcher(url: fileURL, onChange: { [weak self] in
                self?.onChange()
            }) {
                watchers.append(watcher)
            }
        }
    }

    func stopWatching() {
        watchers.removeAll()
        directoryWatcher = nil
    }
}
