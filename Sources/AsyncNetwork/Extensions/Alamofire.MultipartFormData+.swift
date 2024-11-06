import Alamofire
import Foundation

extension Alamofire.MultipartFormData {
    func append(data: Data, bodyPart: MultipartFormData) {
        append(data, withName: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
    }

    func append(fileURL url: URL, bodyPart: MultipartFormData) {
        if let fileName = bodyPart.fileName, let mimeType = bodyPart.mimeType {
            append(url, withName: bodyPart.name, fileName: fileName, mimeType: mimeType)
        } else {
            append(url, withName: bodyPart.name)
        }
    }

    func append(stream: InputStream, length: UInt64, bodyPart: MultipartFormData) {
        append(stream, withLength: length, name: bodyPart.name, fileName: bodyPart.fileName ?? "", mimeType: bodyPart.mimeType ?? "")
    }

    func applyMoyaMultipartFormData(_ multipartBody: [AsyncNetwork.MultipartFormData]) {
        for bodyPart in multipartBody {
            switch bodyPart.provider {
            case .data(let data):
                append(data: data, bodyPart: bodyPart)
            case .file(let url):
                append(fileURL: url, bodyPart: bodyPart)
            case .stream(let stream, let length):
                append(stream: stream, length: length, bodyPart: bodyPart)
            }
        }
    }
}
