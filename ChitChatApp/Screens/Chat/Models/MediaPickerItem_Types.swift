//
//  MediaPickerItem_Types.swift
//  ChitChatApp
//
//  Created by Berkay Emre Aslan on 30.12.2024.
//

import SwiftUI

struct VideoPickerTransferable: Transferable {
   
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return.init(exportingFile.url)
        } importing: { receivedTransferredFile in
            let originalFile = receivedTransferredFile.file
            let uniqueFilename = "\(UUID().uuidString).mov"
            let copiedFile = URL.documentsDirectory.appendingPathComponent(uniqueFilename)
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(url: copiedFile)
        }
    }
}


struct MediaAttachment: Identifiable {
    let id: String
    let type: MediaAttachmentType
    
    var thumbnail: UIImage {
        switch type {
            case .photo(let thumbnail):
                return thumbnail
            case .video(let thumbnail, _):
                return thumbnail
            case .audio:
                return UIImage()
        }
    }
    
    var fileURL: URL? {
        switch type {
            case .photo:
                return nil
            case .video(_, let fileURL):
                return fileURL
            case .audio:
                return nil
        }
    }
}

enum MediaAttachmentType: Equatable {
    case photo(_ thumbnail: UIImage)
    case video(_ thumbnail: UIImage, _ url: URL)
    case audio
    
    static func == (lhs: MediaAttachmentType, rhs: MediaAttachmentType) -> Bool {
        switch (lhs, rhs) {
            case (.photo, .photo), (.video, .video), (.audio, .audio):
                return true
            default:
                return false
        }
    }
}
