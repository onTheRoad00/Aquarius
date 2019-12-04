//
//  GetStringsTool.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation
import ZIPFoundation

enum GSTError: String, Error {
    case pathError = "Fild not exists"
    case getCachePathError = "Get cache path failed."
    case unzipFailed = "Unzip failed."
    case writeResultError = "Faild to crate result file."
}

class GetStringsTool {
    typealias CompletionHandler = (Result<String, GSTError>) -> Void

    static func getStrings(from path: String, _ completion: CompletionHandler?) {
        guard let completion = completion else { return }

        Self.unzip(fileAt: path) { result in
            switch result {
            case .success(let tempPath):
                let strings = Self.filterStrings(at: tempPath)
                let result = Self.readData(at: strings, remove: tempPath)
                // remove cache file when read data finish.
                try? FileManager.default.removeItem(atPath: tempPath)
                completion(Self.writeResult(result, origin: URL(fileURLWithPath: path).lastPathComponent))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension GetStringsTool {
    typealias ResultType = [String: [String: String]]

    static func unzip(fileAt path: String, completion: CompletionHandler?) {
        guard let completion = completion else { return }
        DispatchQueue.global().async {
            let fileManager = FileManager.default

            guard fileManager.fileExists(atPath: path) else {
                completion(.failure(.pathError))
                return
            }

            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
                // TODO error
                completion(.failure(.getCachePathError))
                return
            }

            let stringsCachePath = cachesDirectory.appendingPathComponent("Strings")
            let destinationURL = stringsCachePath.appendingPathComponent(UUID().uuidString)

            do {
                try fileManager.unzipItem(at: URL(fileURLWithPath: path), to: destinationURL)
            } catch {
                completion(.failure(.unzipFailed))
            }

            completion(.success(destinationURL.path))
        }
    }

    static func filterStrings(at path: String) -> [String] {
        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return [] }

        var result = [String]()
        while let next = enumerator.nextObject() {
            if let subPath = next as? String, subPath.hasSuffix("strings") {
                let newPath = url.appendingPathComponent(subPath)
                result.append(newPath.path)
            }
        }
        return result
    }

    static func readData(at paths: [String], remove prefix: String) -> ResultType {
        var result = ResultType()
        for path in paths {
            if let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
                result[path.replacingOccurrences(of: prefix, with: "")] = dictionary
            }
        }

        return result
    }

    static func writeResult(_ result: ResultType, origin name: String) -> Result<String, GSTError> {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            // TODO error
            return .failure(.getCachePathError)
        }

        let resultPath = cachesDirectory.appendingPathComponent("Result.\(name).\(Date()).csv").path

        var string = "Path,Key,Value\n"
        for (path, map) in result {
            var strings = map.map { ",\"\($0)\",\"\($1)\"" }.sorted()
            if let first = strings.first {
                strings[0] = "\n" + path + first
            }
            string += strings.joined(separator: "\n")
        }
        do {
            try string.write(toFile: resultPath, atomically: false, encoding: .utf8)
            return .success(resultPath)
        } catch {
            return .failure(.writeResultError)
        }
    }
}
