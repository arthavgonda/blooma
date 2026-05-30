//
//  BundleResourceLocator.swift
//  prenatalPregnancy
//

import Foundation

extension Bundle {

    func bloomaResourceURL(named name: String, fileExtension: String? = nil) -> URL? {
        if let directURL = url(forResource: name, withExtension: fileExtension) {
            return directURL
        }

        guard let resourceURL else { return nil }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for case let candidateURL as URL in enumerator {
            if let fileExtension = fileExtension {
                guard candidateURL.deletingPathExtension().lastPathComponent == name,
                      candidateURL.pathExtension == fileExtension else { continue }
            } else {
                guard candidateURL.lastPathComponent == name
                        || candidateURL.deletingPathExtension().lastPathComponent == name else { continue }
            }

            return candidateURL
        }

        return nil
    }
}
